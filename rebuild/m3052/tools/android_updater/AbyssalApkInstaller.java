package com.abyssal.updater;

import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.Cursor;
import org.json.JSONObject;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import androidx.core.content.FileProvider;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import java.io.File;
import java.security.MessageDigest;

/** Platform package validation happens AFTER GDScript SHA256 and BEFORE Android installer. */
public final class AbyssalApkInstaller extends GodotPlugin {
    private static final String GAME_ID = "com.abyssaldominion.rebuild";
    private static final String TRUSTED_CERT = "278a2899340d58b3db0aced5e0f306ebb121550bc34dc1e6948783424652fe3b";

    public AbyssalApkInstaller(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "AbyssalApkInstaller";
    }

    // DownloadManager is owned by Android, not Godot's foreground process.
    // It continues transfers when the user switches apps; a new process can
    // reconnect to the system request id from app-private preferences.
    private static final String DOWNLOAD_PREFS = "abyssal_background_apk_v1";
    private static final String RELEASE_ROOT =
        "https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/";
    private static final String UPDATE_DIRECTORY = "abyssal_apk_updater";

    private static boolean trustedDownload(String url, int version, String digest, int length) {
        if (version < 1 || version > 1000000 || length < 1000000 || length > 350000000) return false;
        if (digest == null || !digest.matches("^[0-9a-f]{64}$")) return false;
        final String code = Integer.toString(version);
        return (RELEASE_ROOT + "abyssal-" + code + "-android/ABYSSAL_DOMINION_" + code + ".apk").equals(url);
    }

    private static SharedPreferences preferences(Activity activity) {
        return activity.getSharedPreferences(DOWNLOAD_PREFS, Context.MODE_PRIVATE);
    }

    private static DownloadManager downloads(Activity activity) {
        return (DownloadManager) activity.getSystemService(Context.DOWNLOAD_SERVICE);
    }

    private static File destination(Activity activity, int version) {
        File base = activity.getExternalFilesDir(null);
        if (base == null) return null;
        return new File(new File(base, UPDATE_DIRECTORY), "update-" + version + ".apk");
    }

    // Returns a small machine-readable result. Never pass arbitrary file paths
    // or domains from remote manifests into the native download system.
    @UsedByGodot
    public String enqueueBackgroundApk(String url, int version, String digest, int length) {
        final Activity activity = getActivity();
        if (activity == null) return "activity_missing";
        if (!GAME_ID.equals(activity.getPackageName())
            || !trustedDownload(url, version, digest, length)) return "untrusted_manifest";
        try {
            DownloadManager dm = downloads(activity);
            if (dm == null) return "download_service_missing";
            SharedPreferences prefs = preferences(activity);
            long active = prefs.getLong("request", -1L);
            boolean matching = version == prefs.getInt("version", -1)
                && length == prefs.getInt("length", -1)
                && digest.equals(prefs.getString("digest", ""))
                && url.equals(prefs.getString("url", ""));
            if (active > 0 && matching) {
                try (Cursor cursor = dm.query(new DownloadManager.Query().setFilterById(active))) {
                    if (cursor != null && cursor.moveToFirst()) {
                        int state = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
                        if (state == DownloadManager.STATUS_PENDING || state == DownloadManager.STATUS_RUNNING
                            || state == DownloadManager.STATUS_PAUSED) return "active";
                        if (state == DownloadManager.STATUS_SUCCESSFUL) {
                            File file = destination(activity, version);
                            if (file != null && file.isFile() && file.length() == length)
                                return "active";
                        }
                        // Terminal failure, missing file, or bad size: allow an actual retry.
                    }
                }
            }
            // Replace only our own previously registered DownloadManager request.
            if (active > 0) dm.remove(active);
            File file = destination(activity, version);
            if (file == null || (!file.getParentFile().exists() && !file.getParentFile().mkdirs()))
                return "storage_unavailable";
            if (file.exists() && !file.delete()) return "old_file_locked";
            DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
            request.setTitle("ABYSSAL DOMINION – Update " + version);
            request.setDescription("Download läuft auch beim App-Wechsel weiter");
            request.setMimeType("application/vnd.android.package-archive");
            request.setAllowedOverMetered(true);
            request.setAllowedOverRoaming(false);
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
            request.setDestinationInExternalFilesDir(activity, null, UPDATE_DIRECTORY + "/update-" + version + ".apk");
            long id = dm.enqueue(request);
            if (id <= 0) return "enqueue_failed";
            prefs.edit().putLong("request", id).putInt("version", version)
                .putInt("length", length).putString("digest", digest)
                .putString("url", url).apply();
            return "queued";
        } catch (Exception ex) {
            return "enqueue_failed";
        }
    }

    @UsedByGodot
    public String queryBackgroundApk() {
        final Activity activity = getActivity();
        if (activity == null) return "{\"status\":\"activity_missing\"}";
        JSONObject state = new JSONObject();
        try {
            SharedPreferences prefs = preferences(activity);
            final long id = prefs.getLong("request", -1L);
            final int version = prefs.getInt("version", -1);
            final int expected = prefs.getInt("length", -1);
            state.put("version", version);
            state.put("total", expected);
            if (id <= 0) {
                state.put("status", "missing");
                return state.toString();
            }
            DownloadManager dm = downloads(activity);
            if (dm == null) {
                state.put("status", "service_unavailable");
                return state.toString();
            }
            try (Cursor cursor = dm.query(new DownloadManager.Query().setFilterById(id))) {
                if (cursor == null || !cursor.moveToFirst()) {
                    state.put("status", "missing");
                    return state.toString();
                }
                int status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
                long received = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
                state.put("received", received);
                if (status == DownloadManager.STATUS_PENDING) state.put("status", "pending");
                else if (status == DownloadManager.STATUS_RUNNING) state.put("status", "running");
                else if (status == DownloadManager.STATUS_PAUSED) state.put("status", "paused");
                else if (status == DownloadManager.STATUS_FAILED) {
                    state.put("status", "failed");
                    state.put("reason", cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)));
                } else if (status == DownloadManager.STATUS_SUCCESSFUL) {
                    File file = destination(activity, version);
                    if (file == null || !file.isFile() || file.length() != expected) {
                        state.put("status", "size_mismatch");
                    } else {
                        state.put("status", "complete");
                        state.put("path", file.getCanonicalPath());
                    }
                } else state.put("status", "unknown");
            }
            return state.toString();
        } catch (Exception ex) {
            return "{\"status\":\"query_failed\"}";
        }
    }

    @UsedByGodot
    public String discardBackgroundApk() {
        final Activity activity = getActivity();
        if (activity == null) return "activity_missing";
        try {
            SharedPreferences prefs = preferences(activity);
            long id = prefs.getLong("request", -1L);
            int version = prefs.getInt("version", -1);
            if (id > 0) {
                DownloadManager dm = downloads(activity);
                if (dm != null) dm.remove(id);
            }
            if (version > 0) {
                File file = destination(activity, version);
                if (file != null && file.isFile()) file.delete();
            }
            prefs.edit().clear().apply();
            return "cleared";
        } catch (Exception ex) {
            return "clear_failed";
        }
    }

    private static final String DATA_PREFS = "abyssal_background_data_v1";
    private static final String DATA_RELEASE_ROOT =
        "https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases/download/";
    private static final String DATA_DIRECTORY = "abyssal_data_downloads";

    private static boolean trustedDataDownload(String url, int version, String digest, int length) {
        if (version < 1 || version > 1000000 || length < 1000 || length > 250000000) return false;
        if (digest == null || !digest.matches("^[0-9a-f]{64}$")) return false;
        final String code = Integer.toString(version);
        return (DATA_RELEASE_ROOT + "data-" + code + "/ABYSSAL_DATA_" + code + ".zip").equals(url);
    }

    private static SharedPreferences dataPreferences(Activity activity) {
        return activity.getSharedPreferences(DATA_PREFS, Context.MODE_PRIVATE);
    }

    private static DownloadManager dataDownloads(Activity activity) {
        return (DownloadManager) activity.getSystemService(Context.DOWNLOAD_SERVICE);
    }

    private static File dataDestination(Activity activity, int version) {
        File base = activity.getExternalFilesDir(null);
        if (base == null) return null;
        return new File(new File(base, DATA_DIRECTORY), "data-" + version + ".zip");
    }

    // Returns a small machine-readable result. Never pass arbitrary file paths
    // or domains from remote manifests into the native download system.
    @UsedByGodot
    public String enqueueBackgroundPack(String url, int version, String digest, int length) {
        final Activity activity = getActivity();
        if (activity == null) return "activity_missing";
        if (!GAME_ID.equals(activity.getPackageName())
            || !trustedDataDownload(url, version, digest, length)) return "untrusted_manifest";
        try {
            DownloadManager dm = dataDownloads(activity);
            if (dm == null) return "download_service_missing";
            SharedPreferences prefs = dataPreferences(activity);
            long active = prefs.getLong("request", -1L);
            boolean matching = version == prefs.getInt("version", -1)
                && length == prefs.getInt("length", -1)
                && digest.equals(prefs.getString("digest", ""))
                && url.equals(prefs.getString("url", ""));
            if (active > 0 && matching) {
                try (Cursor cursor = dm.query(new DownloadManager.Query().setFilterById(active))) {
                    if (cursor != null && cursor.moveToFirst()) {
                        int state = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
                        if (state == DownloadManager.STATUS_PENDING || state == DownloadManager.STATUS_RUNNING
                            || state == DownloadManager.STATUS_PAUSED) return "active";
                        if (state == DownloadManager.STATUS_SUCCESSFUL) {
                            File file = dataDestination(activity, version);
                            if (file != null && file.isFile() && file.length() == length)
                                return "active";
                        }
                        // Terminal failure, missing file, or bad size: allow an actual retry.
                    }
                }
            }
            // Replace only our own previously registered DownloadManager request.
            if (active > 0) dm.remove(active);
            File file = dataDestination(activity, version);
            if (file == null || (!file.getParentFile().exists() && !file.getParentFile().mkdirs()))
                return "storage_unavailable";
            if (file.exists() && !file.delete()) return "old_file_locked";
            DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
            request.setTitle("ABYSSAL DOMINION – Update " + version);
            request.setDescription("Download läuft auch beim App-Wechsel weiter");
            request.setMimeType("application/zip");
            request.setAllowedOverMetered(true);
            request.setAllowedOverRoaming(false);
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
            request.setDestinationInExternalFilesDir(activity, null, DATA_DIRECTORY + "/data-" + version + ".zip");
            long id = dm.enqueue(request);
            if (id <= 0) return "enqueue_failed";
            prefs.edit().putLong("request", id).putInt("version", version)
                .putInt("length", length).putString("digest", digest)
                .putString("url", url).apply();
            return "queued";
        } catch (Exception ex) {
            return "enqueue_failed";
        }
    }

    @UsedByGodot
    public String queryBackgroundPack() {
        final Activity activity = getActivity();
        if (activity == null) return "{\"status\":\"activity_missing\"}";
        JSONObject state = new JSONObject();
        try {
            SharedPreferences prefs = dataPreferences(activity);
            final long id = prefs.getLong("request", -1L);
            final int version = prefs.getInt("version", -1);
            final int expected = prefs.getInt("length", -1);
            state.put("version", version);
            state.put("total", expected);
            if (id <= 0) {
                state.put("status", "missing");
                return state.toString();
            }
            DownloadManager dm = dataDownloads(activity);
            if (dm == null) {
                state.put("status", "service_unavailable");
                return state.toString();
            }
            try (Cursor cursor = dm.query(new DownloadManager.Query().setFilterById(id))) {
                if (cursor == null || !cursor.moveToFirst()) {
                    state.put("status", "missing");
                    return state.toString();
                }
                int status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS));
                long received = cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
                state.put("received", received);
                if (status == DownloadManager.STATUS_PENDING) state.put("status", "pending");
                else if (status == DownloadManager.STATUS_RUNNING) state.put("status", "running");
                else if (status == DownloadManager.STATUS_PAUSED) state.put("status", "paused");
                else if (status == DownloadManager.STATUS_FAILED) {
                    state.put("status", "failed");
                    state.put("reason", cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON)));
                } else if (status == DownloadManager.STATUS_SUCCESSFUL) {
                    File file = dataDestination(activity, version);
                    if (file == null || !file.isFile() || file.length() != expected) {
                        state.put("status", "size_mismatch");
                    } else {
                        state.put("status", "complete");
                        state.put("path", file.getCanonicalPath());
                    }
                } else state.put("status", "unknown");
            }
            return state.toString();
        } catch (Exception ex) {
            return "{\"status\":\"query_failed\"}";
        }
    }

    @UsedByGodot
    public String discardBackgroundPack() {
        final Activity activity = getActivity();
        if (activity == null) return "activity_missing";
        try {
            SharedPreferences prefs = dataPreferences(activity);
            long id = prefs.getLong("request", -1L);
            int version = prefs.getInt("version", -1);
            if (id > 0) {
                DownloadManager dm = dataDownloads(activity);
                if (dm != null) dm.remove(id);
            }
            if (version > 0) {
                File file = dataDestination(activity, version);
                if (file != null && file.isFile()) file.delete();
            }
            prefs.edit().clear().apply();
            return "cleared";
        } catch (Exception ex) {
            return "clear_failed";
        }
    }

    @UsedByGodot
    public String installValidatedApk(String absolutePath, int requestedVersion) {
        final Activity activity = getActivity();
        if (activity == null) return "activity_missing";
        try {
            if (!GAME_ID.equals(activity.getPackageName())) return "wrong_installed_package";
            final File externalBase = activity.getExternalFilesDir(null);
            final File apk = new File(absolutePath).getCanonicalFile();
            // Godot user:// can live at files/app_userdata/<game>/abyssal_apk_updater
            // Restrict the exact leaf directory within app-owned sandbox only.
            final File parent = apk.getParentFile();
            final File internalBase = activity.getFilesDir().getCanonicalFile();
            final boolean trustedFolder = parent != null && "abyssal_apk_updater".equals(parent.getName());
            final boolean internal = apk.getPath().startsWith(internalBase.getPath() + File.separator);
            final boolean external = externalBase != null
                    && apk.getPath().startsWith(externalBase.getCanonicalPath() + File.separator);
            final boolean approved = trustedFolder && (internal || external);
            if (!approved
                    || !apk.getName().endsWith(".apk")
                    || !apk.isFile() || apk.length() < 1000000L || apk.length() > 350000000L) {
                return "untrusted_path_or_size";
            }
            if (requestedVersion <= 0 || requestedVersion > 1000000) return "invalid_version";
            final PackageManager pm = activity.getPackageManager();
            final PackageInfo archive;
            if (Build.VERSION.SDK_INT >= 28) {
                archive = pm.getPackageArchiveInfo(apk.getPath(), PackageManager.GET_SIGNING_CERTIFICATES);
            } else {
                archive = pm.getPackageArchiveInfo(apk.getPath(), PackageManager.GET_SIGNATURES);
            }
            if (archive == null || !GAME_ID.equals(archive.packageName)) return "wrong_apk_package";
            final long apkVersion = Build.VERSION.SDK_INT >= 28 ? archive.getLongVersionCode() : archive.versionCode;
            final PackageInfo installed = pm.getPackageInfo(GAME_ID, 0);
            final long installedVersion = Build.VERSION.SDK_INT >= 28 ? installed.getLongVersionCode() : installed.versionCode;
            if (apkVersion != requestedVersion || apkVersion <= installedVersion) return "wrong_apk_version";
            Signature[] signers;
            if (Build.VERSION.SDK_INT >= 28) {
                signers = archive.signingInfo != null ? archive.signingInfo.getApkContentsSigners() : null;
            } else {
                signers = archive.signatures;
            }
            if (signers == null || signers.length != 1) return "invalid_apk_signature";
            final byte[] fingerprint = MessageDigest.getInstance("SHA-256").digest(signers[0].toByteArray());
            if (!TRUSTED_CERT.equals(toHex(fingerprint))) return "certificate_mismatch";
            if (Build.VERSION.SDK_INT >= 26 && !pm.canRequestPackageInstalls()) {
                Intent allow = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES);
                allow.setData(Uri.parse("package:" + GAME_ID));
                activity.startActivity(allow);
                return "permission_required";
            }
            Uri contentUri = FileProvider.getUriForFile(
                activity, GAME_ID + ".abyssalupdater.files", apk);
            Intent install = new Intent(Intent.ACTION_VIEW);
            install.setDataAndType(contentUri, "application/vnd.android.package-archive");
            install.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_GRANT_READ_URI_PERMISSION);
            activity.startActivity(install);
            return "installer_opened";
        } catch (ActivityNotFoundException error) {
            return "system_installer_unavailable";
        } catch (Exception error) {
            // No private paths, URLs, or credentials are returned through GDScript.
            return "android_validation_failed";
        }
    }

    private static String toHex(byte[] raw) {
        final char[] out = new char[raw.length * 2];
        final char[] symbols = "0123456789abcdef".toCharArray();
        for (int i = 0; i < raw.length; i++) {
            out[i * 2] = symbols[(raw[i] >> 4) & 15];
            out[i * 2 + 1] = symbols[raw[i] & 15];
        }
        return new String(out);
    }
}

