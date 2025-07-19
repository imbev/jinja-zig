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
const jinja_zig_dep = b.dependency("jinja_zig", .{
    .target = target,
    .optimize = optimize,
});

const jinja_zig = jinja_zig_dep.module("jinja_zig");

exe.root_module.addImport("jinja_zig", jinja_zig);

```
