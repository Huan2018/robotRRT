function [ end_pose ] = forward_kinematic(theta, robotOrDis, a, alpha,...
    n_Joints)
% this function used to do forward kinematic for robot.
% input variables:
% n_Joints: the joints number, also the length of a, alpha, d & theta
% a: ����ƫ��������
% alpha: ����Ťת�Ƕ�����
% d: ���˳���
% theta: �ؽڽ�
% output variables:
% end_pos : 4x4 matrix for end pose in homogeneous transformation matrix
% ����ⲽ�裺
% 1. �����õ�ǰ����ϵx��x_n����һ������ϵx��x_n+1ƽ�У�����z_n����ǰ��z�ᣬ������
% �ƣ���תtheta_n�Ƕ�
% 2. ��Σ�Ϊʹx_n��x_n+1�Ṳ�ߣ���x_n����z_n��ƽ��d_n
% 3. Ϊʹx_n��x_n+1�Ṳԭ�㣬��x_n��������ƽ��a_n
% 4. Ϊʹz_n��z_n+1���غϣ���x_n����תalpha_a
% 5. ���ؽ������۳˵���α任�������
if nargin < 4 % ��ʾ�ӽṹ�����������
    d = robotOrDis.d;
    a = robotOrDis.a;
    alpha = robotOrDis.alpha;
    n_Joints = robotOrDis.n;
elseif nargin < 5  % ȱʡ�������ؽ�����
    d = robotOrDis.d;
    a = robotOrDis.a;
    alpha = robotOrDis.alpha;
    n_Joints = length(theta);
else
    d = robotOrDis;
end

end_pose = eye(4); 
for i = 1 : n_Joints
    end_pose = end_pose * rot(theta(i), 'z') * trans(d(i), 'z') ...
    * trans(a(i), 'x') * rot(alpha(i), 'x');
end

end

