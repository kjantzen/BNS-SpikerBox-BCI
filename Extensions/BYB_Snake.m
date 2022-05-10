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

            obj.Snake = scatter(obj.SnakeDataX, obj.SnakeDataY,  obj.SnakeSizes,c, 'filled', 'AlphaData',.5);
            obj.Axis.XLim = [obj.Limits(1),obj.Limits(3)];
            obj.Axis.YLim = [obj.Limits(2),obj.Limits(4)];
            obj.Axis.XGrid = 'on';
            obj.Axis.YGrid = 'on';
            obj.Axis.XAxis.Visible = 'off';
            obj.Axis.YAxis.Visible = "off";

   
        end
        function obj = Move(obj, direction)
        
            if strcmp(direction,'Left')
                obj.Direction = obj.Direction - 1;
                if obj.Direction < 1 obj.Direction = 4; end
            elseif strcmp(direction,'Right')
                obj.Direction = obj.Direction + 1;
                if obj.Direction > 4; obj.Direction = 1; end
            end

            obj.SnakeDataX(2:end) = obj.SnakeDataX(1:end-1);
            obj.SnakeDataY(2:end) = obj.SnakeDataY(1:end-1);
            
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