function jfile = tojavafile(filename)

java.lang.System.setProperty('user.dir', pwd)

if isa(filename, 'java.io.File')
    jfile = filename;
elseif ischar(filename)
    jfile = java.io.File(filename);
    if ~jfile.exists
        
        fpath = which(filename);
        if isempty(fpath)
            jfile = [];
        else
            jfile = java.io.File(fpath);
        end
    end
else
    jfile = [];
end