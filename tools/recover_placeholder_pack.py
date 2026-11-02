"""Recover only CRC-verified placeholder assets from an incomplete ZIP prefix.

Never reconstruct runtime code or treat the incomplete archive as valid source.
"""
import pathlib
import struct
import sys
import zlib

def recover(source, destination):
    data = pathlib.Path(source).read_bytes()
    destination = pathlib.Path(destination).resolve()
    offset = count = 0
    while data[offset:offset + 4] == b'PK\x03\x04':
        header = struct.unpack_from('<I5H3I2H', data, offset)
        _, _, flags, method, _, _, crc, packed, size, namesize, extrasize = header
        if flags & 9:  # encrypted or data-descriptor entries need a complete index
            break
        start = offset + 30
        name = data[start:start + namesize].decode('utf-8')
        start += namesize + extrasize
        end = start + packed
        if end > len(data):
            break
        offset = end
        parts = pathlib.PurePosixPath(name).parts
        if 'assets' not in parts:
            continue
        rel = pathlib.PurePosixPath(*parts[parts.index('assets'):])
        if not str(rel).startswith('assets/placeholder_pack/') or name.endswith('/'):
            continue
        assert '..' not in rel.parts and not rel.is_absolute()
        raw = data[start:end] if method == 0 else zlib.decompress(data[start:end], -15)
        assert method in (0, 8) and len(raw) == size and zlib.crc32(raw) == crc, name
        target = destination / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
        count += 1
    print(f'Recovered {count} CRC-verified placeholder files; no runtime code imported.')
    assert count > 0

if __name__ == '__main__':
    recover(*sys.argv[1:])
