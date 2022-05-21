%BYB_Snake - an object for running a basic snake game
%
%Creates and updates the position of a snake drawn as a set of colored
%circles in an a Matlab axis. 
%
%mySnake BYB_Snake(ax) - initializes a new instance of the snake game 
% call mySnake the will be drawn in the matlab axis ax.  
% The snake is created with default parameters for now
% but will be update to allow more customization soon.
%
%mySnake = mySnake.Move(dir) - moves the snake on step in direction dir
%where dir can be one of 'Left', 'Right' or 'Center'. 
classdef BYB_Snake
    properties
        Limits = [0,0,100,100]
        Currentposition = [50,50]
        Speed = 3;
        Direction = 1;
        Axis;
        SnakeDataX ;
        SnakeDataY ;
        Snake;
    end
    properties (Access = private)
        SnakeLength = 10;
        MaxDotSize = 200
        MinDotSize = 50;
        SnakeSizes;
    end
    properties (Constant)
        Directions = {'N', "E", "S", "W"};
    end
    methods
        function obj = BYB_Snake(Axis)
            obj.Axis = Axis;
            obj.SnakeDataX = ones(1,obj.SnakeLength) * 50;
            obj.SnakeDataY = ones(1,obj.SnakeLength) * 50;
            obj.SnakeSizes = linspace(obj.MaxDotSize,obj.MinDotSize, obj.SnakeLength);
            c = linspace(1,10,obj.SnakeLength);

            obj.Snake = scatter(obj.Axis, obj.SnakeDataX, obj.SnakeDataY,  obj.SnakeSizes,c, 'filled', 'AlphaData',.5);
            obj.Axis.XLim = [obj.Limits(1),obj.Limits(3)];
            obj.Axis.YLim = [obj.Limits(2),obj.Limits(4)];
            obj.Axis.XGrid = 'on';
            obj.Axis.YGrid = 'on';
            obj.Axis.XAxis.Visible = 'off';
            obj.Axis.YAxis.Visible = "off";


        end
        function obj = Move(obj, direction)

            %keep track of which direction the snake is travelling 
            %can be either N, S, E or W
            if strcmp(direction,'Left')
                obj.Direction = obj.Direction - 1;
                if obj.Direction < 1 obj.Direction = 4; end
            elseif strcmp(direction,'Right')
                obj.Direction = obj.Direction + 1;
                if obj.Direction > 4; obj.Direction = 1; end
            end

            %create the snake tail by shifting  all the existing values down by 1
            obj.SnakeDataX(2:end) = obj.SnakeDataX(1:end-1);
            obj.SnakeDataY(2:end) = obj.SnakeDataY(1:end-1);

            %get the new direction by adjusting current values by the
            %object speed
            switch obj.Directions{obj.Direction}
                case "N"
                    obj.SnakeDataY(1) = obj.SnakeDataY(1) + obj.Speed;
                    if obj.SnakeDataY(1) > obj.Limits(4); obj.SnakeDataY(1) = obj.Limits(4); end
                case "S"
                    obj.SnakeDataY(1) = obj.SnakeDataY(1) - obj.Speed;
                    if obj.SnakeDataY(1) < obj.Limits(2); obj.SnakeDataY(1) = obj.Limits(2); end
                case "E"
                    obj.SnakeDataX(1) = obj.SnakeDataX(1) + obj.Speed;
                    if obj.SnakeDataX(1) > obj.Limits(3); obj.SnakeDataX(1) = obj.Limits(3); end
                case "W"
                    obj.SnakeDataX(1) = obj.SnakeDataX(1) - obj.Speed;
                    if obj.SnakeDataX(1) < obj.Limits(1); obj.SnakeDataX(1) = obj.Limits(1); end
            end

            obj.Snake.XData = obj.SnakeDataX;
            obj.Snake.YData = obj.SnakeDataY;
            obj.Axis.XLim = [obj.Limits(1),obj.Limits(3)];
            obj.Axis.YLim = [obj.Limits(2),obj.Limits(4)];
            drawnow
        end




    end
end