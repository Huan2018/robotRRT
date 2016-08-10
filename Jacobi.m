function [J, pose_each, R_accu, P_accu, w_accu, P_end] = Jacobi(q, robotOrDis, ...
a, alpha)
% This function is used to compute Jacobi matrix under the current state
% of robot.

% input variables:
% q: input 1x7 angle, for each joint
% robotOrDis: if the robot data is read from a structure(meaning .mat file),
%   then it is a structure input, the following input can be regardless. In
%   the other case, this is a 1x7 matrix for d in DH
% a: 1x7 matrix for a in DH
% alpha: 1x7 matrix for alpha in DH

% output variables:
% J: Jacobi matrix
% pose_each: (4x4xn matrix)pose expression of each joint, include R_each 
%   & P_each
% R_accu: rotate matrix for current z coordinate system in base coordinate
%   system, 3x3x(n+1) matrix. one position expanded
% P_accu: current O(0,0,0)'s coordinate in base coordiante system, 3x(n+1)
%   matrix, one position expanded
% w_accu: current z-axis's coordinate in base coordinate system, 3x(n+1)
%   matrix, one position expanded
% P_end: the posiontion for end point coordinate system in current
%   ordinate system, 3xn matrix

% Jocobi������㷽������Whitneyʸ�����㷽��������˵��J = [J1, .. , Jn], ��
% ��ÿһ��Ji, ��Ҫ����ԣ�x,y,z,alpha,beta,gamma)����������ƫ������������ʵ
% ������ϵO-XiYiZi��Zi���ڻ����꣨O-X0Y0Z0)�еı�ʾ��ǰ������ĩ���ٶ���x,y,z��
% ���������������ý��ٶ�ʸ������ǰ�߼���õ��ģ����λ��ʸ����ĩ��λ������ڵ�ǰ
% ����ϵ(O-XiYiZi)�ɵõ�

% attention!������õĽ���������ϵ�����ǣ�������ϵO-x0y0z0��theta_1�غϣ�Ҳ����
% ˵��������ϵ�Դ�һ�����ɱ������ؽ�1����ת��theta_1����Ȼ��O-x1y1z1���ڹؽ�2
% �ϣ��������ƣ����ؽ�O-x7y7z7���ڲ�����ĩ�ˡ���ˣ�����Jacobi������ٶ���ʱ
% ��һ��Ϊ������Ľ��ٶȣ�Ӧ��Ϊ��0,0,1)����z�᱾��֮�����γ�����ת���󣬴�
% һλ��������λ��ʸ��ʱ��Ҳ�Ǵӻ����꿪ʼ��ע�����˳��;�������塣Ϊ��ʹ��
% ĩ��λ�õĽ��ٶ������������ʽ�R_accu��P_accu��w_accu����һλ����Jacobi����
% ����Ҫ������λ��ע�⡣

% if input argument is 2, then read data from structure

if nargin == 2
    d = robotOrDis.d;
    a = robotOrDis.a;
    alpha = robotOrDis.alpha;
else
    d = robotOrDis;
end

% to enhance the use of this function, read n itself, not always .mat file
n = length(q);
m = 6;
J = zeros(m, n);
% pose_each is each pose matrix in Euler ZXZ form, the same with the other
% two
pose_each = zeros(4, 4, n); 
R_each = zeros(3, 3, n);
P_each = zeros(3, n);

for i = 1:n
    pose_each(:, :, i) = forward_kinematic(q(i), d(i), a(i), alpha(i), 1);
    R_each(:, :, i) = pose_each(1:3, 1:3, i);
    P_each(:, i) = pose_each(1:3, 4, i);
end

% to compute the accumulate pose matric, R for Euler angle and  
% P for position, n+1 is a expand bit under n joints.
R_accu = zeros(3, 3, n+1);
P_accu = zeros(3, n+1);
R_accu(:, :, 1) = eye(3);
P_accu(:, 1) = zeros(3, 1);
w_accu = zeros(3, n+1);
% compute angle velocity
for i = 2:n+1
    R_accu(:, :, i) = R_accu(:, :, i-1)*R_each(:, :, i-1); 
    P_accu(:, i) = P_accu(:, i-1) + R_accu(:, :, i-1) * P_each(:, i-1);
end
% the 1:n columns of w_accu matrix is the Jacobi angle velocity, also the 
% third column of R_accu matrix, that is the result [R_accu x (0, 0, 1)], 
% meaning the z-axis's expression in the base station.
w_accu(:, :) = R_accu(:, 3, :);
J(4:6, :) = w_accu(:, 1:n);
% compute velocity
% P_end is the relative coordinate in base coordinate system from current
% coordinate system to the end point coordinate system, and then using 
% v = w X r to compute velocity.
P_end = zeros(3, n);
for i = 1:n
   P_end(:, i) = P_accu(:, n+1) - P_accu(:, i);
   J(1:3, i) = cross(w_accu(:, i), P_end(:, i));
end

end
