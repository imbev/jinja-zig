## jinja-zig

An implementation of the Jinja templating language in Zig.

Compatible with Zig 0.14

Open source under the BSD-3-Clause license

***This project is currently WIP and missing many features!***

### Add to your project

Run the following command:
```shell
zig fetch --save git+https://github.com/imbev/jinja-zig
```

Then add the following to your `build.zig`:

```zig
const jinja_zig = b.dependency("jinja_zig", .{
        .target = target,
        .optimize = optimize,
    });

exe.root_module.addImport("jinja_zig", jinja_zig.module("jinja_zig"));

```

Example use in a Zap project
```zig
const std = @import("std");
const zap = @import("zap");
const jinja = @import("jinja_zig");

pub fn on_request(r: zap.Request) !void {
    r.sendBody(try jinja.eval_file(std.heap.page_allocator, "index.jinja")) catch return;
}
```

### Roadmap

- [x] Plain HTML
- [ ] Statements
    - [ ] for
    - [ ] if
    - [ ] macro
    - [ ] call
    - [ ] filter
        - [ ] upper()
        - ...
    - [ ] set
    - [ ] extends
    - [ ] block
    - [ ] include
    - [ ] import
- [ ] Expressions
    - [ ] Literals
        - [x] string
        - [ ] integer
        - [ ] float
        - [ ] list
        - [ ] tumple
        - [ ] dict
        - [ ] boolean
    - [ ] Math
        - [ ] \+
        - ...
    - [ ] Comparisons
        - ...
    - [ ] Logic
        - [ ] and
        - [ ] or
        - [ ] not
        - [ ] (expr)
    - [ ] in
    - [ ] is
    - [ ] filter
    - [ ] concatenate
    - [ ] callable
    - [ ] attribute
    - [ ] inline if
    - [ ] struct methods
- [x] Comments
    - [x] Single-line
    - [x] Multi-line
