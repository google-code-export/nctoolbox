function out  = stringtokenizer(S, n, Token)
% STRINGTOKENIZER - return the nth word in token delimited string
%
% Use as: out = stringtokenizer(S, n)
%         out = stringtokenizer(S, n, Token)
%
% Inputs: S = String to be parsed using Token
%         n = the Nth String Element to return
%         Token = String token delimiter
%
% Output: out = the nth element delimited by Token
%
% Example:
%   stringtokenizer('dog cat boy girl hog' ,3)
%    ans = 'boy'
%
%   stringtokenizer('dog; cat; boy; girl; hog' ,2, ';')
%    ans = ' cat'

% Brian Schlining
% 12 Oct 1999

if nargin < 3
   Token = ' ';
end

if ~isstr(Token)
   out = badmsg('  The token delimiter must be a string');
   return
end

if length(S) < 2
   out = badmsg('  Input string is too short to be tokenized');
   return
end

if n <= 0
   out = badmsg('  n must be greater than 0');
   return
end
   
i         = findstr(S, Token);
i         = [0 i length(S)+1];
di        = diff(i);
good      = find(di ~= 1);
i         = [i(good) i(end)];
numTokens = length(i) - 1;
OK        = 1;

while OK
   
   try
      out = S(i(n)+1:i(n+1)-1);
      out = trim_(out, Token);
   catch
      out = badmsg(['  Could not find element ' num2str(n) ' using the  token ''' Token '''']);
      return
   end
   
   if isempty(out) & n < numTokens
      n = n + 1;
   else
      return
   end
   
end

%===========================
function S = trim_(S, Token)
i = findstr(Token,S);
if ~isempty(i) & length(S) > 1
   S = S(1:min(i)-1);
end

%=======================
function out = badmsg(S)
warning(S);
out = [];


