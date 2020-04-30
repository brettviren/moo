{
    types : {
        string: "std::string",
        integer: "int",
        boolean: "bool",
        notype: "void",
    },
    handlers : {
        runtime: 'throw std::runtime_error("%s");',
        return: 'return %s;',
    }
    
}
