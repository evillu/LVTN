function objs = initObject( )

%   id name of object
%   type group of object, if there 1 object type = 1, 2 object type = 2
%   box : 10 last box of current frame
%   hit : check if new histograme matches to this hist
%   hists: histogram of object
%   age : 
    objs = struct(...
        'id',{},...
        'type',{},...
        'box',{},...
        'hit',{},...
        'hists',{},...
        'age',{}...
    );
end

