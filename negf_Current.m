function [ Ids, Ids_tn ] = negf_Current( valleyNum, Em, k_count, E, FF1, FF2 )
%% �Լ����� : NEGF�� �̿��Ͽ� �������� ����մϴ�.
% �� �Ķ���ʹ� ������ �����ϴ�. 
% valleyNum : x���������� valley ��ȣ (#1: m_l, #2 & #3 : m_t)
% Em : mode ������(subband minimum)
% k_count : �ؼ��� mode ��ȣ 
% E : �ؼ��� ����� ������ ��� ��� 
% FF1 : Source�ܿ����� Fermi �Լ���, E index�� ����
% FF2 : Drain�ܿ����� Fermi �Լ���, E index�� ����

%% �۷ι� ����� �ҷ��ɴϴ�. 
if (3 < valleyNum ) || (valleyNum < 1)  % ���� üũ (1~3)
    disp(sprintf('option : out of range!'));
    return;
end
global mass;    % valley�� ���� ���� ��ȿ ���� 
m_x = mass.m_x(valleyNum);

global xmesh;   % x���� mesh
global const_i; % ��ġ�� ������ ���

% x���� ����, �� ��� ���� ��������
x_dlt = xmesh.dlt(1)*1e-9;
nx = xmesh.nx - 2;

% ��� �ҷ�����
q = const_i.q;
hBar = const_i.hBar;

% ������ ���� ��ȯ ([eV] -> [J])
E = E*q;
Em = Em(:,k_count)*q;

%% NEGF �ؼ��� ����
% Hamiltonian ��� �� T�� ���� : H = T(kinetic energy) + U(potential energy)
t = +(hBar^2/(2*m_x*x_dlt^2));  % ��� t = hBar^2/(2 m a^2)
sbase_first_row = zeros(nx,1);  
sbase_first_row(1) = -2; sbase_first_row(2) = 1;
sbase = sparse(toeplitz(sbase_first_row, sbase_first_row'));
T = -t*sbase;   % T �ϼ�

% ������ ��� ������ 
nE = size(E,2)-1; % ��꿡 ���� ������ ��� ����, ��� ������ ������ ���б������� ���  
dE = E(2) - E(1); % ������ ��� ����

% ��� ����
i = sqrt(-1);     % ��� i ���� 

% ���� ���� 
sigma1 = zeros(nx,nx);  % self ������ ���� (source)
sigma2 = zeros(nx,nx);  % self ������ ���� (drain)
Ids = zeros(1,nE);      % �������� ���� �����ϴ� ������ ���� 
Ids_tn = zeros(1,nE);   % �������� ���� �����ϴ� ������ ���� 

% NEGF�� ���� ������ ��� ���� 
for j = 1:nE
    % ����� ������ ���� 
    E_l = E(j) + dE/2;  % ���б����� ����� ���� ������ ��忡�� �߰����� ���� 
    
    % ���� ������ ��� 
    % matlab acos �Լ��� [-1,+1]�� [��, 0]�� �����Ǵ� �� ������ 
    % [-1,+1] ���� ���������� ���Ҽ��� �����Ͽ� ������ �ʴ� ������ �� 
    % ������ �ʿ��� ������ ���� 
    E_ratio1 = 1 - ( E_l - Em(1) )/(2*t);   
    ka1 = acos( E_ratio1 +2*(E_ratio1 < -2) +2*(E_ratio1 < -4) );   
    sigma1(1,1) = -t*exp(i*ka1);	
    E_ratio2 = 1 - ( E_l - Em(nx) )/(2*t);  
    ka2 = acos( E_ratio2 +2*(E_ratio2 < -2) +2*(E_ratio2 < -4) );   
    sigma2(nx, nx) = -t*exp(i*ka2); 
    
    % �׸� �Լ� ��� 
    G = ( E_l*eye(nx) -T -diag(Em) - sigma1 - sigma2 )\eye(nx, nx);
    
    gamma1 = i*(sigma1 - sigma1');  % ����(���������� �����Ʈ) (source)
    gamma2 = i*(sigma2 - sigma2');  % ����(���������� �����Ʈ) (drain)
    
    % ���� ��� 
    % ���� ��� : T = sum(real(diag(gamma1*G*gamma2*G')))
    % factor 2�� ���� ����
    Ids(j) = 2*q*x_dlt/(2*pi*hBar)*(FF1(j)-FF2(j))*sum(real(diag(gamma1*G*gamma2*G')))*dE;
    
    % �ͳθ� ���� ��� 
    if E_l < max(Em)
        Ids_tn(j) = Ids(j);
    end
end
% ������ �뿪�� ���� ������ �հ��Ͽ� ����
Ids = sum(Ids,2);
Ids_tn = sum(Ids_tn,2);

end
