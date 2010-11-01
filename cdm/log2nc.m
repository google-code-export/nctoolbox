function log2nc(logname, ncname)
% LOG2NC - Convert an MBARI binary AUV log data file to netcdf.
%
% Use as: log2nc(logname, ncname)
%
% Inputs: logname = The log to be converted to netcdf
% Output: ncname = The name of the netcdf file to be created.

% Brian Schlining
% 2010-05-25

% The song-n-dance with the tojavafile /fromjavafile is needed to correctly
% resolve path (Java's pwd and matlab's pwd are not the same unless this is done
% which would lead to files being written to unexpected places
targetfile = fromjavafile(tojavafile(ncname));
fprintf(1, 'Creating %s\n', targetfile);

nc = ucar.nc2.NetcdfFileWriteable.createNew(targetfile);  

if isempty(nc)
    error(['Failed to create ' ncname '. Check that you have write permission.']);
end

% Open the log file, get the device name from the header
fid = fopen(logname, 'r', 'l');
s = fgetl(fid); 
instrumentName = stringtokenizer(s, 3);

% Generate the standard global attributes using null values
nc.addGlobalAttribute('title', 'AUV data');
nc.addGlobalAttribute('created', datestr(now, 31));
nc.addGlobalAttribute('source', logname);
nc.addGlobalAttribute('history0', [datestr(now, 31) ': Netcdf file generated in matlab using log2nc']);
nc.addGlobalAttribute('deploymentName', 'null');
nc.addGlobalAttribute('instrumentId', 'null');
nc.addGlobalAttribute('instrumentName', instrumentName);
nc.addGlobalAttribute('instrumentType', 'null');
nc.addGlobalAttribute('instrumentMfg', 'null');
nc.addGlobalAttribute('instrumentSerialNumber', 'null');
nc.addGlobalAttribute('instrumentModel', 'null');


% AUV files always have a single dimension of time
nc.addUnlimitedDimension('time');

%% Generate the netcdf schema. This is done by parsing the header of the log file
i = 0;
while(~feof(fid))
    s = fgetl(fid);  
    i = i + 1;
    if (strcmp(stringtokenizer(s, 2), 'begin'))
        break    
    end
    
    % Parse the variable info
    data(i).type = stringtokenizer(s, 2);
    data(i).shortName = stringtokenizer(s, 3);
    data(i).format = stringtokenizer(s, 4);
    data(i).longName = deblank(stringtokenizer(s, 2, ','));
    
    switch data(i).shortName
        case 'time'
            data(i).units = 'seconds since 1970-01-01 00:00:00Z';
        otherwise         
            data(i).units = stringtokenizer(s, 3, ',');
    end
    
    % If there's a duplicate variable name, keep appending '_' until it's
    % unique
    while ~isempty(nc.findVariable(data(i).shortName))
       data(i).shortName = [data(i).shortName '_'];
    end
    
    % Map the dataformats correctly   
    switch lower(data(i).type)
        case {'float'}
            data(i).type = 'float32'; 
            v = nc.addVariable(data(i).shortName, ucar.ma2.DataType.FLOAT, 'time');
            data(i).size = 4;
        case {'integer'}
            data(i).type = 'int32';
            v = nc.addVariable(data(i).shortName, ucar.ma2.DataType.INT, 'time');
            data(i).size = 4;
        case {'short'}
            data(i).type = 'int16';
            v = nc.addVariable(data(i).shortName, ucar.ma2.DataType.SHORT, 'time');
            data(i).size = 2;
        otherwise
            data(i).type = 'double'; 
            v = nc.addVariable(data(i).shortName, ucar.ma2.DataType.DOUBLE, 'time');
            data(i).size = 8;
    end
    
    % Create variable attributes
    if ~isempty(data(i).longName) 
        a = ucar.nc2.Attribute('long_name', data(i).longName);
        v.addAttribute(a);
    end
    
    if ~isempty(data(i).units)
        a = ucar.nc2.Attribute('units', data(i).units);
        v.addAttribute(a);
    end
    
end

nc.create(); % end define mode. NetCDF file is ready for data

%% Pre allocate memory
fprintf(1, 'Reading %s\n', logname);
byteStart = ftell(fid);
fseek(fid, 0, 'eof');
byteEnd = ftell(fid);
fseek(fid, byteStart, 'bof');
nBytes = byteEnd - byteStart;
recordLength = 0;
for i = 1:length(data)
    recordLength = recordLength + data(i).size;
end
nRecords = floor(nBytes/recordLength);
for i = 1:length(data)
    data(i).data = ones(1, nRecords) * NaN;
end


%% Read the data from the log
for i = 1:length(data)
    byteStart = ftell(fid);
    data(i).data = fread(fid, nRecords, data(i).type, recordLength - data(i).size);
    fseek(fid, byteStart + data(i).size, 'bof');
end
fclose(fid);

%% Write the data to the netcdf
fprintf(1, 'Writing data to %s\n', targetfile);
for i=1:length(data)
    fprintf(1, '\tWriting ''%s''\n', data(i).shortName);
    writedata(nc, data(i).shortName, data(i).data);
end

nc.close()

end % END log2nc

%%
function writedata(nc, variablename, d)
% writedata - write data to a netcdf file
%
% Use as:
%   writedata(nc, variablename, d)
%
% Inputs:
%   nc = a netcdf object
%   variableName = the string variable to write data into
%   d = the data to writedata

    v = nc.findVariable(variablename);
    a = ucar.ma2.Array.factory(v.getDataType(), length(d));
    for i = 1:length(d)
        a.setObject(i - 1, d(i));
    end
    nc.write(variablename, a);
    nc.flush();
end % END writedata

%%
function jfile = tojavafile(filename)
% tojavafile - Creates a java File object from a matlab path
%
% Use as:
%   jfile = tojavafile(filename)
%
% Inputs:
%   filename - The string path of the filename
%
% Output:
%   jfile = a java.io.File object pointing to the path you supplied


java.lang.System.setProperty('user.dir', pwd);

if isa(filename, 'java.io.File')
    jfile = filename;
elseif ischar(filename)
    jfile = java.io.File(filename);
else
    jfile = [];
end

end % END tojavafile

%%
function filename = fromjavafile(fileobj)
% fromjavafile - Returns the full path of a file from a java obj
%
% Use as:
%   filename = fromjavafile(fileobj)
%
% Inputs:
%   fileobj = an object to resolve as a string filepath
%
% Output:
%   filename = The full path to the fileobj, as a string, if fileobj is an 
%              instance of a java.io.File object. If a string is passed in then
%              the same string is returned (i.e. not changes). Any other object
%              passed in returns []

if isa(fileobj, 'java.io.File')
    filename = char(fileobj.getCanonicalPath);
elseif ischar(fileobj)
    filename = fileobj;
else
    filename = [];
end

end % END fromjavafile