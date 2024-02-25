
const dependencies = @import("dependencies.zig");

/// get the ID of a process
fn get_process_id(window_name: [*c]const u8) u32
{
    const hwnd : dependencies.windows.HWND = dependencies.windows.FindWindowA(null, window_name);
    var process_id : u32 = undefined;

    _ = dependencies.windows.GetWindowThreadProcessId(hwnd, &process_id);
    return process_id;
}

/// retrieve a handle to a process with the specified flags
fn retrieve_handle(flags : u32, process_id : u32, out_handle : *?*anyopaque) bool
{
    if (process_id == 0) return false;

    out_handle.* = dependencies.windows.OpenProcess(flags, 0, process_id);
    if (dependencies.windows.GetLastError() == 0) return true;

    return false;
}

/// allocates external RWX memory in target process
fn allocate_external_memory(external_base : *?*anyopaque, process_handle : dependencies.windows.HANDLE, size : u64) bool
{
    external_base.* = dependencies.windows.VirtualAllocEx(process_handle, null, size, 0x1000 | 0x2000, dependencies.windows.PAGE_EXECUTE_READWRITE );

    if(external_base.* == null) return false;
    return true;
}

pub fn main() void
{
    var process_id : u32 = get_process_id("AssaultCube");

    var access_rights : ?*anyopaque = undefined;
    dependencies.std.debug.print("open handle {any}\n", .{retrieve_handle(0x1F0FFF, process_id,&access_rights )});

    var external_memory_base : ?*anyopaque = undefined;
    dependencies.std.debug.print("memory allocated {any}\n", .{allocate_external_memory(&external_memory_base, access_rights, 20)});
    dependencies.std.debug.print("base at 0x{any}\n", .{external_memory_base});

    _ = dependencies.windows.system("pause>0");
}

