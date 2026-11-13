param([Parameter(Mandatory = $true)][string[]]$Executable)
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;

public static class CarouseldeskIconVerifier {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern IntPtr LoadLibraryExW(string file, IntPtr reserved, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr FindResourceW(IntPtr module, IntPtr name, IntPtr type);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern uint SizeofResource(IntPtr module, IntPtr resource);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr LoadResource(IntPtr module, IntPtr resource);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr LockResource(IntPtr resource);
    [DllImport("kernel32.dll")]
    static extern bool FreeLibrary(IntPtr module);

    static byte[] ReadResource(IntPtr module, int name, int type) {
        IntPtr resource = FindResourceW(module, new IntPtr(name), new IntPtr(type));
        if (resource == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error(), "Missing icon resource");
        int size = checked((int)SizeofResource(module, resource));
        IntPtr loaded = LoadResource(module, resource);
        IntPtr pointer = LockResource(loaded);
        if (pointer == IntPtr.Zero || size == 0) throw new InvalidDataException("Empty icon resource");
        byte[] data = new byte[size];
        Marshal.Copy(pointer, data, 0, size);
        return data;
    }

    public static void Verify(string executable, string icon) {
        byte[] expected = File.ReadAllBytes(icon);
        int count = BitConverter.ToUInt16(expected, 4);
        IntPtr module = LoadLibraryExW(executable, IntPtr.Zero, 0x22);
        if (module == IntPtr.Zero) throw new Win32Exception(Marshal.GetLastWin32Error());
        try {
            byte[] group = ReadResource(module, 101, 14);
            if (BitConverter.ToUInt16(group, 2) != 1 || BitConverter.ToUInt16(group, 4) != count)
                throw new InvalidDataException("Unexpected icon group");
            for (int i = 0; i < count; i++) {
                int icoEntry = 6 + i * 16;
                int groupEntry = 6 + i * 14;
                for (int j = 0; j < 12; j++)
                    if (expected[icoEntry + j] != group[groupEntry + j])
                        throw new InvalidDataException("Icon dimensions or format differ from brand asset");
                int size = BitConverter.ToInt32(expected, icoEntry + 8);
                int offset = BitConverter.ToInt32(expected, icoEntry + 12);
                int id = BitConverter.ToUInt16(group, groupEntry + 12);
                byte[] actual = ReadResource(module, id, 3);
                if (actual.Length != size) throw new InvalidDataException("Icon size mismatch");
                for (int j = 0; j < size; j++)
                    if (expected[offset + j] != actual[j])
                        throw new InvalidDataException("Executable contains an outdated or incorrect icon");
            }
        } finally {
            FreeLibrary(module);
        }
    }
}
'@

$icon = (Resolve-Path (Join-Path $PSScriptRoot '..\icon.ico')).Path
foreach ($file in $Executable) {
    $path = (Resolve-Path -LiteralPath $file).Path
    [CarouseldeskIconVerifier]::Verify($path, $icon)
    Write-Output "Verified embedded carouseldesk icon: $file"
}
