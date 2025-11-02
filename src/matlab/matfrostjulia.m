classdef matfrostjulia < handle & matlab.mixin.indexing.RedefinesDot
% matfrostjulia - Embedding Julia in MATLAB
%
% MATFrost enables quick and easy embedding of Julia functions from MATLAB side.
%
% Characteristics:
% - Converts MATLAB values into objects of any nested Julia datatype (concrete entirely).
% - Interface is defined on Julia side.
% - A single redistributable MEX file.
% - Leveraging Julia environments for reproducible builds.
% - Julia runs in its own mexhost process.



    properties (SetAccess=immutable)
        julia             (1,1) string
    end

    properties (Access=private)
        id                (1,1) uint64
        matfrostjuliacall (1,1) string
        mh                     matlab.mex.MexHost
        project           (1,1) string
        socket            (1,1) string
        timeout           (1,1) uint64
    end

    properties (Constant)
        USE_MEXHOST (1,1) logical = false
    end

    methods
        function obj = matfrostjulia(argstruct)
            arguments                
                argstruct.version     (1,1) string
                    % The version of Julia to use. i.e. 1.12 (Juliaup channel)
                argstruct.bindir      (1,1) string {mustBeFolder}
                    % The directory where the Julia binary is located.
                    % This will overrule the version specification.
                    % NOTE: Only needed if version is not specified.
                argstruct.project     (1,1) string = ""

                argstruct.socket      (1,1) string = string(tempname) + ".sock"

                argstruct.timeout     (1,1) uint64 = 600e3 % 10 minutes
            end
            
            obj.id = uint64(randi(1e9, 'int32'));
            obj.socket = argstruct.socket;
            obj.timeout = argstruct.timeout;

            if isfield(argstruct, 'bindir')
                bindir = argstruct.bindir;
            elseif isfield(argstruct, 'version')
                bindir = juliaup(argstruct.version);
            else
                [status, bindir] = shell('julia', '-e', 'print(Sys.BINDIR)');
                assert(~status, "matfrostjulia:julia", ...
                        "Julia not found on PATH")
            end


            if ispc
                obj.julia = fullfile(bindir, "julia.exe");
            elseif isunix
                error("matfrostjulia:osNotSupported", "Linux not supported yet.");
                % obj.julia = fullfile(bindir, "julia");
            else
                error("matfrostjulia:osNotSupported", "MacOS not supported yet.");
            end

            
            % 
            % obj.project = argstruct.project;
            argstruct.socket
            obj.start_server();
            obj.connect_server();

        end


    end

    methods (Access=private)

        function obj = start_server(obj)

            obj.mh = mexhost();

            if ~isempty(obj.project)
                project = sprintf("--project=""%s""", obj.project);
            else
                project = "";
            end

            bootstrap = fullfile(fileparts(mfilename("fullpath")), "bootstrap.jl");

            createstruct = struct;
            createstruct.id = obj.id;
            createstruct.action = "START";
            createstruct.cmdline = sprintf("""%s"" %s ""%s"" ""%s""", obj.julia, project, bootstrap, obj.socket);
            createstruct.socket = obj.socket;
            
            if obj.USE_MEXHOST
                obj.mh.feval("matfrostjuliacall", createstruct);
            else
                matfrostjuliacall(createstruct);
            end
        end


        function obj = connect_server(obj)


            connectstruct = struct;
            connectstruct.id = obj.id;
            connectstruct.action = "CONNECT";
            connectstruct.socket = obj.socket;
            connectstruct.timeout = obj.timeout;

         
            if obj.USE_MEXHOST
                obj.mh.feval("matfrostjuliacall", connectstruct);
            else
                matfrostjuliacall(connectstruct);
            end

        end

        function delete(obj)

            destroystruct = struct;
            destroystruct.id = obj.id;
            destroystruct.action = "STOP";

            if obj.USE_MEXHOST
                obj.mh.feval("matfrostjuliacall", destroystruct);
            else
                matfrostjuliacall(destroystruct);
            end
        end
    end
   
    methods (Access=protected)
        function varargout = dotReference(obj,indexOp)
            % Calls into the loaded julia package.
            
            if indexOp(end).Type ~= matlab.indexing.IndexingOperationType.Paren
                throw(MException("matfrostjulia:invalidCallSignature", "Call signature is missing parentheses."));
            end

            fully_qualified_name_arr = arrayfun(@(in) string(in.Name), indexOp(1:end-1));
             
            args = indexOp(end).Indices;

            callstruct.id = obj.id;
            callstruct.action = "CALL";
            callstruct.fully_qualified_name = join(fully_qualified_name_arr, ".");
            callstruct.args    = args(:);


            if obj.USE_MEXHOST
                jlo = obj.mh.feval("matfrostjuliacall", callstruct);
            else
                jlo = matfrostjuliacall(callstruct);
            end
            
            if jlo.status == "SUCCESFUL"
                varargout{1} = jlo.value;
            elseif jlo.status =="ERROR"
                throw(jlo.value)
            end

        end

        function obj = dotAssign(obj,indexOp,varargin)
            % required for matlab.mixin.indexing.RedefinesDot
        end
        
        function n = dotListLength(obj,indexOp,indexContext)
            % required for matlab.mixin.indexing.RedefinesDot
            n=1;
        end
    end
end
