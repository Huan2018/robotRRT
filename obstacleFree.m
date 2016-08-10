function res = obstacleFree(Point, obstacle)
% This function used to detect if the current position of machine is in
% collision with the obstacle.
res = 1;
safespace = 0.1;
numObstacle = size(obstacle, 1);
numPoint = size(Point, 2);
dimPoint = 3;
tig = zeros(numPoint, 1);
for k = 1:numObstacle
    if obstacle(k, 1) == 1
        % ��ⷽ���ϰ���
        for i = 1:numPoint
            for j = 1:dimPoint
                if abs(Point(j,i)-obstacle(k,j+1)) < obstacle(k,j+4)/2 ...
                    + safespace 
                    tig(j) = 1;
                else
                    tig(j) = 0;
                end
            end
            if min(tig) == 1
                res = 0;
                break;
            end
        end
    elseif obstacle(k,1)==2
        %��������ϰ���
        for i = 1:numPoint
            if norm(Point(:,i)'-obstacle(k,2:4)) < abs(obstacle(k,5))
                res = 0;
                break;
            end
        end
    end
    if res == 0
        break;
    end

end