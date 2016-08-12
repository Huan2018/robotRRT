function [q_path, X_path, Time, H, success] = mostLikelyGrade(q0, ...
    Euler_v, L, steps, obstacle, robot)
% �����ݶȷ�(most likely grade method, MLG��)���л�е�����˶�ѧ�켣�Ż���ͨ��
% �����ķ������ؽڽ�q���ٶ�dq
% �������:
% q0Ϊ��ʼ�ؽڱ���
% Euler_vΪĩ��ִ����ŷ�����ٶ�
% L��ʾ��е���˶���·��
% steps�Ը����Ĺ켣����ֱ�߲岹����С����
% obstacle��ʾ�ϰ�����Ϣ
% robotΪ��е��DH���������
% �������:
% qΪ���Źؽڹ켣
% XΪq��Ӧ��λ�˹켣
% rEΪ��е��ĩ��λ��ʸ��
% REΪ��е��ĩ����̬����
% P0(:,n)Ϊ��е�۵�n������������λ��ʸ��
% TimeΪʱ������
% HΪĿ�꺯��
% successΪ��־��������success=1����ʾ�滮�ɹ�����success=0,��ʾ�滮���ɹ���

% global variables
global COMPILE

% �����е�۲���
n = robot.n;
m = robot.m;
q_max = robot.q_max;
q_min = robot.q_min;
a_max = robot.acce_max;
% nΪ�ؽڱ���ά��
% q_max��q_minΪ�ؽڱ�����������
% a_max��ʾ�ؽ��ٶȴ�С�仯�����ֵ
% nΪ���ɶ�
% mΪĩ�����ɶȣ�����Ϊ6


% initialization
q_path = zeros(n, steps + 1);
dq = zeros(n, steps);
X_path = zeros(m, steps + 1);
Time = zeros(1, steps + 1);
s = zeros(1, steps + 1);
X_s = zeros(m, 1);
factor = zeros(1, n);
zero_norm = (1e-3)^6;
delta_L = L / double(steps);
success = 1;
% band the minimum velocity
v_min = 0.05;
% normalize the euler velocity
Euler_v = Euler_v / norm(Euler_v, 2);
i = 1;
dq(:, 1) = zeros(n, 1);
q_path(:, i) = q0;
while i <= steps
    % get jacobi matrix and relative useful matrix
    [jac, pos, ra, pa, ~, ~] = Jacobi(q_path(1:n, i), robot);
    % perform euler angle velocity
    X_path(1:6, i) = matrix2pose(ra(:, :, n+1), pa(:, n+1));
    X_s(1:3) = X_path(1:3, i);
    X_s(4:6) = eulerV2absV(X_path(4:6), Euler_v);
    % to do boundary & obstacle detect
    if ~(obstacleFree([X_path(1:3,i) pa(:, :)], obstacle)  ...
            && boundaryFree(q_path(:, i), q_max, q_min))
        success = 0;
        break;
    end
    % to see if jtj is strange
    jtj = jac * jac';
    det_jtj = det(jtj);
    if zero_norm < abs(det_jtj)
        % pinv means expand inverse of jac, that is , j_pinv = jac'/jtj
        j_pinv = pinv(jac);
        Y = j_pinv * X_s;
        A = eye(n) - j_pinv * jac;
        dH = gradMLG(q_path(:, i), q_max, q_min, n);
        % column transformation in l-u deformation
        [~, u, ~] = lu(A'); 
        % get B from B's transposition, that A = [B 0]*Q
        B = u';
        B = B(:, n-m);
        % compute ds and velocity
        main_matrix = [Y'*Y, Y'*B; B'*Y, B'*B];
        ds_vel = -1/2*( main_matrix\[Y'*dH; B'*dH] );
        ds = ds_vel(1, 1);
        vel = ds_vel(2, 1);
        % to see if ds is big enough
        if ds < v_min
            vel = vel*v_min/ds;
            ds = v_min;
        end
        % compute dq
        dq(:, i+1) = Y*ds + B*vel;
        % to see if accelerate is suitable, if not, suitify it
        t = delta_L / ds;
        for j = 1:n
            factor(j) = abs(dq(j, i+1) - dq(j, i))/t/a_max(j);
        end
        max_fac = max(factor);
        if 1 < max_fac
            ds = ds / max_fac;
            vel = vel / max_fac;
        end
        if ds < v_min
            ds = v_min;
        end
        % after doing things above, get the ending dq
        dq(:, i+1) = Y*ds + B*vel;
        t = delta_L / ds;
        Time(i + 1) = Time(i) + t;
        q_path(:, i+1) = q_path(:, i) + dq(:, i+1)*t;
        s(i+1) = s(i) + ds*t;
        % compile output
        COMPILE = 0;
        if COMPILE 
            toolkit('matrix', Y, 'Y is: ');
            toolkit('matrix', B, 'B is: ');
            toolkit('matrix', ds, 'ds is: ');
            toolkit('matrix', vel, 'vel is: ');
            toolkit('matrix', dq, 'dq is: ');
            toolkit('matrix', t, 't is: ');
            toolkit('matrix', delta_L, 'dL is: ');
        end
        COMPILE = 1;
    else
        success = 0;
        break;
    end
    i = i + 1;
end
T = i;
H = zeros(1,T);
if success
     % compute x_path(:, i) to make rank same to q_path
     [~, ~, ra, pa, ~, ~] = Jacobi(q_path(:, i), robot);
     X_path(:, i) = matrix2pose(ra(:, :, n+1), pa(:, n+1));
     if ~(obstacleFree([X_path(1:3,i) pa(1:3, 4, :)], obstacle)  ...
            && boundaryFree(q_path(:, i), q_max, q_min))
        success = 0;
        return
    end
    %���Ŀ�꺯��H(x)
    sq = zeros(n,1);
    q_norm = pi;
    for j = 1:T
        for i = 1:n
            if q_max(i,1) - q_path(i,j) < q_norm || q_path(i,j) - q_min(i,1) < q_norm
                sq(i,1) = 1/4*(q_max(i,1)-q_min(i,1))^2/((q_max(i,1)-q_path(i,j))...
                    *(q_path(i,j)-q_min(i,1)));
            else
                sq(i,1)=0;
            end
        end
        H(1,j) = sum(sq);
    end
    H = H / double(n);
end
end