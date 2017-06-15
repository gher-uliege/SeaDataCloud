module ODVspreadsheet

using Logging

# Configure logging (replace WARNING by DEBUG, INFO, ERROR or CRITICAL)
Logging.configure(level=WARNING);


function initProfileList(line)
    """
    Create an empty list of lists,
    the number of internal lists is the number of columns

    List of lists is preferred because the length of each list is
    not always the same.
    """
    debug("Creating new profile (list of list) with empty values")

    # Compute number of columns
    ncolumns = length(line);
    debug("No. of columns: " * string(ncolumns))

    profile = []
    for i in 1:ncolumns
        push!(profile, [line[i]])
    end

    return profile
end

function getNonEmptyInd(line)
    nonempty(x) = length(x) > 0;
    nonempty_ind = find(nonempty, line);
    return nonempty_ind;
end

"""
Define composite type
that will contain: the metadata, the column labels and an array of profiles
"""

global ODVspreadsheet3
type ODVspreadsheet3
        metadata::Dict{String,String}
        columnLabels::Array{SubString{String},1}
        profileList::Array{Any,1}
end

function readODVspreadsheet(datafile)

    """
    The function will return a composite type that will store:
    1. The general metadata of the spreadsheet
    2. The labels of the columns
    3. The individual profiles
    """

    # metadata will be stored in a dictionary
    # ODV doc: Comment lines start with two slashes  // as first two characters
    metadata = Dict{String, String}()

    # Context manager
    open(datafile, "r") do f
        line = readline(f)

        # Read the metadata (lines starting with //)
        while line[1:2] == "//"

            # Identify metadata fields using regex
            # (name of the field is between < > and </ >)
            m = match(r"<(\w+)>(.+)</(\w+)>", line)

            if m != nothing
                debug("Match found")
                debug(m[1] * ": " * m[2])
                # Add key - value in the dictionnary
                metadata[String(m[1])] = String(m[2])
            end
            line = readline(f);
        end

        # Read the column labels and set number of columns
        #ODV doc: must be the first non-comment line in the file
        #ODV doc: must provide columns for all mandatory meta-variables
        columnline = line
        columnLabels = split(chomp(columnline), '\t')
        ncols = length(columnLabels);
        debug("No. of columns: " * string(ncols))

        # Create an array that will store all the profiles
        profileList = []

        # Loop on the lines
        jj = 0
        profile = [];
        nprofiles = 0;

        while !eof(f)
            jj += 1;
            line = split(chomp(readline(f)), "\t");

            # Count empty values
            nonempty_ind = getNonEmptyInd(line);
            debug("Indices of the non-empty columns :")
            debug(nonempty_ind);

            # If the first value (Station) is not empty,
            # then it's a header line
            if (nonempty_ind[1] == 1)
                debug("Working with a header line")
                debug("Adding the profile to the array")
                push!(profileList, profile)

                # Initiate a profile (list of lists)
                nprofiles += 1;
                debug("Create a new, empty profile")
                profile = initProfileList(line)
            else
                debug("Adding values to the existing profile")
                for ii in nonempty_ind
                    push!(profile[ii], line[ii]);
                end
            end
        end

        info("No. of profiles in the file: " * string(nprofiles))
        ODVdata = ODVspreadsheet3(metadata, columnLabels, profileList)
        return ODVdata
    end
end

export WTF, readODVspreadsheet

end
