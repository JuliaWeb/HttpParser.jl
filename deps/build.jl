using BinDeps

depsdir = joinpath(Pkg.dir(),"HttpParser","deps")
prefix=joinpath(depsdir,"usr")
uprefix = replace(replace(prefix,"\\","/"),"C:/","/c/")
target = joinpath(prefix,"lib/libhttp_parser.$(BinDeps.shlib_ext)")

run(@build_steps begin
    ChangeDirectory(Pkg2.Dir.path("HttpParser"))
    FileRule("deps/src/http-parser/Makefile",`git submodule update --init`)
    FileRule(target,@build_steps begin
        ChangeDirectory(Pkg2.Dir.path("HttpParser","deps","src","http-parser"))
        CreateDirectory(dirname(target))
        `make library`
        `cp libhttp_parser.so $target`
    end)
end)
