### 목적

기존 EC2 기반 3-Tier 프로젝트의 To-do 서비스를 컨테이너화하고, EKS에서 배포·관리하도록 확장했다.

(기존 프로젝트)</br>
https://github.com/riptae/aws-final-tier3

<img width="80%" alt="EKS" src="https://github.com/user-attachments/assets/04aa3679-ddb4-407c-88d0-4447064a7ac0" /><br>

<br>
<br>

### Terraform 인프라와 작업 단계.
실행 단위를 인프라와 애드온으로 나눴다.
1. `terraform/`에서 VPC, EKS, Managed Node Group, ECR, RDS를 생성한다.
2. `addons/`에서 인프라 state를 참조해 AWS Load Balancer Controller를 설치한다.
3. 컨테이너 이미지를 ECR에 업로드하고, Kubectl로 DB Secret과 Kubernetes 매니페스트를 적용한다.

<br>
<img width="80%" alt="ㅇㅇㅇ" src="https://github.com/user-attachments/assets/2c3d7ec8-c3db-4a92-8ff5-5883619c73be" />
<br>
<br>
<br>

### 권한 관련.
이전에는 AWS CLI에 admin권한을 넣고 그거 하나로 Terraform이 AWS API에 접근해서 리소스를 생성하고 관리했는데,<br>
리소스와 EKS를 만들고 나서 K8S API에 접근하는 것을 포함, 다양한 권한들이 필요하다.

| No. | 작업자와 작업 | 필요한 권한 | 구성 방식 |
| --- | --- | --- | --- |
| 1 | Terraform이 AWS 리소스 생성 | 각 AWS 리소스 생성·관리 권한 | AWS CLI에 구성한 STS 임시 자격 증명 사용 |
| 2 | 로컬 Docker가 이미지를 ECR에 Push | ECR 인증·이미지 업로드 권한 | AWS CLI로 ECR 로그인 토큰 발급 → Docker 로그인 |
| 3 | 로컬 kubectl·Helm이 EKS에 배포 | Kubernetes 리소스 생성·관리 권한 | AWS CLI로 EKS 인증 토큰 발급 + EKS Access Entry·접근 정책 |
| 4 | EKS 서비스가 클러스터 관리 | EKS 운영에 필요한 AWS 권한 | Cluster IAM Role |
| 5 | 워커 노드가 ECR 이미지 Pull·노드 운영 | ECR 읽기·노드 및 CNI 운영 권한 | Node IAM Role |
| 6 | Controller Pod가 ALB 생성·관리 | ALB·Target Group 등 관리 권한 | ServiceAccount에 IAM Role 연결(IRSA) |
<br>
<img width="50%" alt="image" src="https://github.com/user-attachments/assets/d8a27e6f-1a79-4495-9d5a-bd70d23c4a75" />
<br>
또 리소스와 배포를 전부 실행한 뒤에도, Web Console에서 모니터링시에도 추가 권한이 필요했다.<br>

| No. | 작업자와 작업 | 필요한 권한 | 구성 방식 |
| --- | --- | --- | --- |
| 7 | 웹 콘솔 사용자가 Pod 상태 조회 | EKS 콘솔 조회 + Kubernetes 리소스 조회 권한 | 로그인한 IAM 사용자·Role의 IAM 정책 + EKS Access Entry·View 정책 |

<br>
<br>

### ALB, Ingress, Service

기존 EC2 기반 3-Tier에서는 Terraform으로 ALB와 Target Group을 직접 생성하고 Web EC2를 대상으로 등록했다.

이번에는 Web Pod가 재생성되거나 확장될 때 IP가 바뀔 수 있어, Target Group의 대상 등록도 이에 맞춰 자동으로 관리해야 했다.

이를 위해 Helm Chart로 ALB Controller를 EKS에 설치, Controller는 Ingress와 연결된 Web Service 정보를 바탕으로 ALB와 Target Group을 생성하고, Pod 변경에 맞춰 대상을 갱신하도록 구성했다.

`target-type: ip`를 사용해 ALB가 Web Pod IP로 직접 요청을 전달하도록 했다.

<br>
<br>
### 작동 검증.<br>
<img width="80%" alt="image" src="https://github.com/user-attachments/assets/b9373695-17db-46ac-b20f-31754440d5a2" />
<br>
ALB DNS로 접속.

<br>
<img width="50%" alt="image" src="https://github.com/user-attachments/assets/a3e4c7e2-33bc-4fe8-83ef-e543126d1285" />
<br>
CRUD 체크.
<br>
<br>
<br>

### EC2기반 3-TIER와 차이 비교
| 항목 | 기존 EC2 기반 | EKS 기반 |
| --- | --- | --- |
| 서비스 실행 환경 | `user_data`와 Ansible로 nginx등 | Docker 이미지에 정의 |
| 배포 | Bastion에서 파일 복사와 서비스 실행 | 이미지 참조를 지정한 Deployment 적용 |
| DB 연결 설정 | 서버의 `app.env` | Kubernetes Secret을 환경변수로 주입 |

