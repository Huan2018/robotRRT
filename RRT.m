function [output_q, output_Xfree, output_T, success] = RRT(q0, X_max, ...
    X_min, rE_goal, RE_goal, obstacle)
% ���ڹ������ɿռ��RRT�����л�е�۹켣�滮
% ���������
% q0:��е�۳�ʼ�ؽڽ�
% key:��ʾĩ�˱����������������key(i)=0,��ʾĩ�˵�i�������̶���������key(i)=1,
% ��ʾĩ�˵�i�������˶�����
% X_max,X_min:�ֱ��ʾ�����ռ�������С�߽�
% X_goal:��ʾĩ��Ŀ��λ��(x,y,z,alpha,beta,gamma),ǰ���������꣬������Ϊ����
% Euler��,�������õ�
% rE_goal:ĩ��λ��[x, y, z]
% RE_goal:��ʾĩ��Ŀ����̬����3x3���󣬽Ƕȱ任����Euler ZXZ�任��ͬ
% X_goal��
% obstacle���ϰ���

% ���������
% Outputq:�滮�õĹؽڽ�����
% OutputT:�滮�õ�ʱ������
% OutputX:�滮�õ�ĩ��λ������
% OutputRE:�滮�õ�ĩ��λ������

% define global variables
global COMPILE;
global SHOW_DIAGRAM;
% read in robot data
robot = load('robotDH.mat');
n = robot.n;
m = robot.m;
% �����е�۲���
% ���У�
% d,a,alphaΪDH����
% d(i)��x_i-1��x_i����z_i-1��ľ��룻
% a(i)��z_i-1��z_i��x_i�ľ��룻
% alpha(i)��z_i-1��z_i��x_i�ļн�(�����ֹ���)
% theta(i)Ϊ��x_i-1��x_i��z_i-1�ļн�(�����ֹ���),Ϊ���ɱ���,��ʼֵ���ٶ�Ϊ0
% q_max��q_minΪ�ؽڱ�����������
% nΪ�ؽڽ������������ɶ���
% mΪλ�˱���

% initialize
% K�滮����
K = 2000; 
q_path = zeros(n, K);
X_free = zeros(m, K);
parent = zeros(1, K);
cost = zeros(1, K);
Time = zeros(1, K);
% compute the pose of the end point
X_goal = zeros(m, 1);
X_goal(1:6) = matrix2pose(RE_goal, rE_goal);
% compute the pose of the initial point
q_path(:, 1) = q0;
[~, ~, R0, P0, ~, ~] = Jacobi(q0, robot);
X_free(1:6, 1) = matrix2pose(R0(:, :, n+1), P0(:, n+1));
% draw the goal and initial point
if SHOW_DIAGRAM
    subplot(331);
    plot3(X_goal(1), X_goal(2), X_goal(3), 'b+');
    hold on;
    plot3(X_free(1, 1), X_free(2, 1), X_free(3, 1), 'gd');
    hold on;
    subplot(332);
    plot3(X_goal(4), X_goal(5), X_goal(6), 'b+');
    hold on;
    plot3(X_free(4, 1), X_free(5, 1), X_free(6, 1), 'gd');
    hold on;
end
% numTree take down the current number of point in the tree
numTree = 1;
% inializition and target position obstacle detection and boundary detection
i = 1; % the iterator variable
% factor and connect
factor = max(abs(X_max-X_min));
connect = 0;
endPoint = zeros(1, K); % take donw the points which near to goal
rank_end = 0; % the current length of endPoint array
num_fail = 0; % the total times fail between while
% test if initial and goal point is in collision with obstacle or boundary
if obstacleFree(P0, obstacle) && boundaryFree(X_free, X_max, X_min)...
        && obstacleFree(X_goal, obstacle) ...
        && boundaryFree(X_goal, X_max, X_min)
    i = i+1;
    num_fail = 1;
    rank_end = rank_end + 1;
else
    i = K+1;
end
while i <= K && num_fail <= 2*K
   % sample function, random point in free space
   X_rand = sample(X_min, X_max); 
   if obstacleFree(X_rand, obstacle)
       % doing extend here, generate new tree point and added it to 
       % the original tree
        [q_path, X_free, parent, cost, Time, success] = extend(q_path, ...
            X_free, parent, cost, Time, X_rand, numTree+1, factor, ...
            obstacle, robot);
        if COMPILE
            if success
                toolkit('array', i, 'current rank is: ');
                toolkit('array', X_goal(:), 'the goal point is: ');
                toolkit('array', X_free(:, 1), 'the initial point is: ');
                toolkit('array', q_path(:, i), 'the new point is: ');
                toolkit('array', X_free(:, i), 'the new pointx is: ');
                toolkit('array', X_rand(:), 'the rand point is: ');
                sss = input('message');
            else
                disp('extend not success');
            end
        end
        COMPILE = 1;
        if success
            % draw the rand point, new point to the graph
            if SHOW_DIAGRAM
                subplot(331);
                plot3(X_free(1, :), X_free(2, :), X_free(3, :), 'r*');
                axis('equal');
                axis([-1, 1, -1, 1, 0, 1.5]);
                title('X_free');
                hold on;
                subplot(332);
                plot3(X_free(4, :), X_free(5, :), X_free(6, :), 'r.');
                hold on;
            end
            % numTree change to i, means there are i points in the tree
            numTree = i;
            length = norm(X_goal - X_free(:, i));
            steps = double(int32(100*length));
            [q_p, X_p, T_p, ~, succ] = mostLikelyGrade(q_path(:, i), ...
                X_goal-X_free(:, i), length, steps, obstacle, robot);
            connect = 0;
            if succ && goalTest(X_p(:, steps+1), X_goal)
                connect = 1;
                endPoint(rank_end) = i;
                rank_end = rank_end + 1;
                break;
            end
            if goalTest(X_free(:,i), X_goal) && rank_end <= int8(K/10)
                endPoint(rank_end) = i;
                rank_end = rank_end + 1;
            end
            i = i + 1;
        else
            num_fail = num_fail + 1;
        end
   else
       num_fail = num_fail + 1;
   end
end

if 1 < rank_end
    success = 1;
    % find path from q0 to goal in the tree
    nendPoint = endPoint(1 : rank_end-1);
    [optimal_q, optimal_Xfree, optimal_T] = findPath(q_path, X_free, ...
        parent, cost, Time, nendPoint, K);
    if connect
        optimal_q = [optimal_q q_p];
        optimal_Xfree = [optimal_Xfree X_p];
        optimal_T = [optimal_T; T(k)+T_p];
    end
    % smooth the path
    [output_q, output_Xfree, output_T] = smooth(optimal_q, ...
        optimal_Xfree, optimal_T);
else
    success = 0;
    output_q = q_path(:, 1);
    output_Xfree = X_free(:, 1);
    output_T = 0;
end
end