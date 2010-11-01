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


% Brian Schlining
% 2010-04-28

if isa(fileobj, 'java.io.File')
    filename = char(fileobj.getCanonicalPath);
elseif ischar(fileobj)
    filename = fileobj;
else
    filename = [];
end