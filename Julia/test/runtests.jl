include("../ODVspreadsheet.jl")

using Logging
using ODVspreadsheet
Logging.configure(level=WARNING);
using Base.Test

@testset "ODV spreadsheet reading" begin
    include("test_read_file_latin1.jl");
    include("test_read_small_file.jl");
end
