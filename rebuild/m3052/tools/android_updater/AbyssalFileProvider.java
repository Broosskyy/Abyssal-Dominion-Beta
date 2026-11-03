package com.abyssal.updater;

import androidx.core.content.FileProvider;

/** Separate scoped updater provider, avoids overriding Godot's built-in provider. */
public final class AbyssalFileProvider extends FileProvider {
    public AbyssalFileProvider() { super(); }
}

