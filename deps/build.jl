using BinDeps

@BinDeps.setup

aliases = []
@windows_only begin
    if WORD_SIZE == 64
        aliases = ["libhttp_parser64"]
    else
        aliases = ["libhttp_parser32"]
    end
end
libhttp_parser = library_dependency("libhttp_parser", aliases=aliases)

@unix_only begin
    # Get source
    cd(Pkg.dir("HttpParser","deps"))
    isdir("src") && run(`rm -rf src`)
    mkdir("src"); cd("src")
    run(`git clone https://github.com/joyent/http-parser.git`)
    cd("http-parser")
    run(`git checkout v2.3`)

    # Where the library will go
    target = joinpath(Pkg.dir("HttpParser","deps","usr","lib"),
                        "libhttp_parser.$(BinDeps.shlib_ext)")

    provides(SimpleBuild,
        (@build_steps begin
            ChangeDirectory(Pkg.dir("HttpParser"))
            FileRule(target, @build_steps begin
                ChangeDirectory(Pkg.dir("HttpParser","deps","src"))
                CreateDirectory(Pkg.dir("HttpParser","deps","usr","lib"))
                MakeTargets(["-C","http-parser","library"])
                `cp http-parser/libhttp_parser.so.2.3 $target`
            end)
        end),[libhttp_parser], os = :Unix)
end

# Windows
@windows_only begin
    provides(Binaries,
         URI("https://julialang.s3.amazonaws.com/bin/winnt/extras/libhttp_parser.zip"),
         libhttp_parser, os = :Windows)
end

@BinDeps.install [:libhttp_parser => :lib]
