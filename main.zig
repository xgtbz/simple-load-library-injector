const dependencies = @import("dependencies.zig");


/// get the ID of a process
fn get_process_id(window_name: [*c]const u8) u32 {
    const hwnd: dependencies.windows.HWND = dependencies.windows.FindWindowA(null, window_name);
    var process_id: u32 = undefined;

    _ = dependencies.windows.GetWindowThreadProcessId(hwnd, &process_id);
    return process_id;
}

/// retrieve a handle to a process with the specified flags
fn retrieve_handle(flags: u32, process_id: u32, out_handle: *?*anyopaque) bool {
    if (process_id == 0) return false;

    out_handle.* = dependencies.windows.OpenProcess(flags, 0, process_id);
    if (dependencies.windows.GetLastError() == 0) return true;

    return false;
}

/// allocates external RWX memory in target process
fn allocate_external_memory(external_base: *?*anyopaque, process_handle: dependencies.windows.HANDLE, size: u64) bool {
    external_base.* = dependencies.windows.VirtualAllocEx(process_handle, null, size, 0x1000 | 0x2000, dependencies.windows.PAGE_EXECUTE_READWRITE);

    if (external_base.* == null) return false;
    return true;
}


pub fn main() void 
{

    var process_id: u32 = get_process_id("AssaultCube");

    const dll_name : [*c]const u8 = "C:\\Users\\user\\source\\repos\\test_module\\x64\\Debug\\test_module.dll";
    const dll_length : u64 = dependencies.windows.strlen(dll_name);

    const output_handle : dependencies.windows.HANDLE = dependencies.windows.GetStdHandle(dependencies.windows.STD_OUTPUT_HANDLE);
    _ = dependencies.windows.SetConsoleTextAttribute(output_handle, 12);

    var access_rights: ?*anyopaque = undefined;
    var status_code : bool = retrieve_handle(0x1F0FFF, process_id, &access_rights);

    dependencies.std.debug.print("open handle {any}\n", .{status_code});

    var external_memory_base: ?*anyopaque = undefined;
    status_code = allocate_external_memory(&external_memory_base, access_rights, dll_length);

    dependencies.std.debug.print("memory allocated {any}\n", .{status_code});

    dependencies.std.debug.print("base at 0x{any}\n", .{external_memory_base});

    const export_rt : ?*const fn(...) callconv(.C) c_longlong = dependencies.windows.GetProcAddress(dependencies.windows.GetModuleHandleA("kernel32.dll"), "LoadLibraryA");
    const status_code_int : c_int = dependencies.windows.WriteProcessMemory(access_rights, external_memory_base, dll_name, dll_length, null);

    dependencies.std.debug.print("wpm status code: {any}\n", .{status_code_int});
    dependencies.std.debug.print("exported routine: {any}\n", .{export_rt});
    
    const start_routine : dependencies.windows.LPTHREAD_START_ROUTINE = @ptrCast(@alignCast(export_rt));
    const thread_handle : dependencies.windows.HANDLE = dependencies.windows.CreateRemoteThread(access_rights, null, 0, start_routine, external_memory_base, 0, null );

    dependencies.std.debug.print("thread handle: {any}\n", .{thread_handle});

    _ = dependencies.windows.system("pause>0");
}
