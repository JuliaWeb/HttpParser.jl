using BinDeps
using Compat
using Compat.Libdl

@BinDeps.setup

version=v"2.8.1"

aliases = []
if is_windows()
    if Sys.WORD_SIZE == 64
        aliases = ["libhttp_parser64"]
    else
        aliases = ["libhttp_parser32"]
    end
end

# This API used for validation was introduced in 2.6.0, and there have no API changes between 2.6 and 2.7
function validate_httpparser(name, handle)
    handle == C_NULL && return false
    p = Libdl.dlsym_e(handle, :http_parser_url_init)
    if p == C_NULL
        is_windows() && warn("Looks like your binary is old. Please run `rm($(sprint(show, joinpath(dirname(@__FILE__), "usr"))); recursive = true)` to delete the old binary and then run `Pkg.build($(sprint(show, "HttpParser")))` again.")
        return false
    end
    return true
end

libhttp_parser = library_dependency("libhttp_parser", aliases=aliases,
                                     validate=validate_httpparser)

if is_unix()
    src_arch = "v$version.zip"
    src_url = "https://github.com/nodejs/http-parser/archive/$src_arch"
    src_dir = "http-parser-$version"

    pretarget = "libhttp_parser.$(Libdl.dlext)"
    target = Compat.Sys.islinux() ? "$pretarget.$version" : "libhttp_parser.$version.$(Libdl.dlext)"
    targetdwlfile = joinpath(BinDeps.downloadsdir(libhttp_parser), src_arch)
    targetsrcdir  = joinpath(BinDeps.srcdir(libhttp_parser), src_dir)
    targetlib     = joinpath(BinDeps.libdir(libhttp_parser), pretarget)

    provides(SimpleBuild,
        (@build_steps begin
            CreateDirectory(BinDeps.downloadsdir(libhttp_parser))
            FileDownloader(src_url, targetdwlfile)
            FileUnpacker(targetdwlfile,BinDeps.srcdir(libhttp_parser),targetsrcdir)
            @build_steps begin
                CreateDirectory(BinDeps.libdir(libhttp_parser))
                @build_steps begin
                    ChangeDirectory(targetsrcdir)
                    `rm -f $src_dir/$target $targetlib`
                    FileRule(targetlib, @build_steps begin
                        ChangeDirectory(BinDeps.srcdir(libhttp_parser))
                        CreateDirectory(dirname(targetlib))
                        MakeTargets(["-C",src_dir,"library"], env=Dict("SONAME"=>pretarget))
                        `cp $src_dir/$target $targetlib`
                    end)
                end
            end
        end), libhttp_parser, os = :Unix)
end

# Windows
if is_windows()
    provides(Binaries,
         URI("https://s3.amazonaws.com/julialang/bin/winnt/extras/libhttp_parser_2_8_1.zip"),
         libhttp_parser, os = :Windows)
end

@BinDeps.install Dict(:libhttp_parser => :lib)
