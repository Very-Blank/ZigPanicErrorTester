const std = @import("std");
const builtin = std.builtin;

pub fn expectCompileError(code: []const u8) !void {
    const allocator: std.mem.Allocator = std.heap.smp_allocator;

    const file = try std.fs.cwd().createFile("TempFileExpectCompileError.zig", .{});
    _ = file.write(code) catch |err| {
        file.close();
        return err;
    };

    file.close();

    var childProcess: std.process.Child = std.process.Child.init(
        &[_][]const u8{ "zig", "test", "TempFileExpectCompileError.zig" },
        allocator,
    );

    childProcess.stdin_behavior = .Ignore;
    childProcess.stdout_behavior = .Ignore;
    childProcess.stderr_behavior = .Ignore;

    const term = try childProcess.spawnAndWait();
    try std.fs.cwd().deleteFile("TempFileExpectCompileError.zig");

    switch (term) {
        .Exited => |value| {
            switch (value) {
                0 => return error.TestFailed,
                1 => return,
                else => {
                    return error.TestDidNotRun;
                },
            }
        },
        else => {
            return error.TestDidNotRun;
        },
    }
}

test "Testing panics" {
    try expectCompileError(
        \\test "This should panic!" {
        \\    @compileError("hell");
        \\}
    );

    try expectCompileError(
        \\test "This should panic!" {
        \\    if(true){
        \\        unreachable;
        \\    } else{
        \\
        \\    }
        \\}
    );
}

test "Valid code" {
    expectCompileError(
        \\const std = @import("std");
        \\test "This shouldn't panic!" {
        \\    std.debug.print("this doesn't fail", .{});
        \\}
    ) catch return;

    return error.TestInvalid;
}
