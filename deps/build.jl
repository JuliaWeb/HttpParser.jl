using BinDeps

@BinDeps.setup

version=v"2.6.2"

aliases = []
@windows_only begin
    if WORD_SIZE == 64
        aliases = ["libhttp_parser64"]
    else
        aliases = ["libhttp_parser32"]
    end
end

libhttp_parser_jl = library_dependency("libhttp_parser_jl", aliases=aliases)

@unix_only begin
    src_arch = "v$version.zip"
    src_url = "https://github.com/nodejs/http-parser/archive/$src_arch"
    src_dir = "http-parser-$version"

    target = "libhttp_parser_jl.$(BinDeps.shlib_ext)"
    targetdwlfile = joinpath(BinDeps.downloadsdir(libhttp_parser_jl),src_arch)
    targetsrcdir = joinpath(BinDeps.srcdir(libhttp_parser_jl),src_dir)
    targetlib    = joinpath(BinDeps.libdir(libhttp_parser_jl),target)

    provides(SimpleBuild,
        (@build_steps begin
            CreateDirectory(BinDeps.downloadsdir(libhttp_parser_jl))
            FileDownloader(src_url, targetdwlfile)
            FileUnpacker(targetdwlfile,BinDeps.srcdir(libhttp_parser_jl),targetsrcdir)
            @build_steps begin
                CreateDirectory(BinDeps.libdir(libhttp_parser_jl))
                @build_steps begin
                    ChangeDirectory(targetsrcdir)
                    FileRule(targetlib, @build_steps begin
                        ChangeDirectory(BinDeps.srcdir(libhttp_parser_jl))
                        CreateDirectory(dirname(targetlib))
                        MakeTargets(["-C",src_dir,"library"], env=Dict("SONAME"=>target))
                        `cp $src_dir/$target $targetlib`
                    end)
                end
            end
        end), libhttp_parser_jl, os = :Unix)
end

# Windows
@windows_only begin
    provides(Binaries,
         URI("https://julialang.s3.amazonaws.com/bin/winnt/extras/libhttp_parser.zip"),
         libhttp_parser_jl, os = :Windows)
end

@BinDeps.install Dict(:libhttp_parser_jl => :lib)

