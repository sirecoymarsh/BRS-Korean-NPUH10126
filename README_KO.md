# BLACK★ROCK SHOOTER THE GAME 한국어 패치 v1.0

대상: 미국 PSN판 `NPUH10126`

이 배포본에는 원본 게임 ISO가 포함되어 있지 않습니다. 사용자가 보유한
지원 대상 원본으로 새 한국어판 ISO를 생성합니다. 원본 ISO는 수정하거나
삭제하지 않습니다.

## 지원 원본

- 크기: `1,360,363,520`바이트
- SHA-256: `4735b0d0f59d480991fd8cf034e5b0f2d98798cec275ab4162df09b8a6d23f0e`

이 크기와 해시가 모두 일치하지 않으면 패처가 작업을 거부합니다.

## 배포 파일

- `BRS_Korean_NPUH10126_v1.0.brspatch`: 이진 델타 패치
- `Apply-KoreanPatch.ps1` / `Apply-KoreanPatch.bat`: 설치
- `Restore-Original.ps1` / `Restore-Original.bat`: 검증된 한국어판 출력 제거
- `CHECKSUMS.sha256`: 배포 파일 무결성 목록
- `REPORTS`: 빌드, 언어/그래픽 UI 감사 및 PPSSPP QA 보고서
- `LICENSES`: Noto Sans KR 및 Galmuri 관련 OFL 고지

## 설치

가장 쉬운 방법은 원본 ISO를 `Apply-KoreanPatch.bat` 위에 끌어다 놓는
것입니다. 또는 이 폴더에서 Windows PowerShell을 열고 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Apply-KoreanPatch.ps1" -SourceIso "<원본_ISO_경로>"
```

출력 경로를 생략하면 원본과 같은 폴더에 `_Korean_v1.0.iso`가 붙은 새
파일이 생성됩니다. 별도 출력 경로를 지정할 수도 있습니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Apply-KoreanPatch.ps1" -SourceIso "<원본_ISO_경로>" -OutputIso "<출력_ISO_경로>"
```

완성본 검증값:

- 크기: `1,370,918,912`바이트
- SHA-256: `554b67aff4fc0fd95ad50a2ac5f470192a40d0b868cdc2f5bbfd2e2ad4f5b313`

## 그래픽 UI 한글화

주요 메뉴, 아이템, 옵션, 전투/필드 시스템 UI의 그래픽 라벨
`100`개를
`27`개 PTMD에 반영했습니다.
결과물은 `9`개 게임 컨테이너를
통해 ISO에 직접 내장되어 있으므로, 이 그래픽 UI 한글화를 위해 별도의
PPSSPP 텍스처 교체 기능이나 외부 텍스처 팩을 설치할 필요가 없습니다.

메뉴 아틀라스는 원본 알파 행에서 측정한 UV 영역을 그대로 유지하며,
Galmuri 픽셀 한글을 안티앨리어싱 없이 각 영역 안에만 렌더링했습니다.
PPSSPP 스테이지 선택 화면에서 `저장`, `로드`, `메뉴`가 서로 섞이거나
위아래로 갈라지지 않는 것을 실기 확인했습니다.

필드의 `★MENU` 화면에 있는 `CUSTOMIZE / ITEMS / CHALLENGES / OPTIONS /
EXP / NEXT / LEVEL`은 여러 고정 UV 조각을 조합하는 초소형 아틀라스입니다.
이 영역은 한글을 강제로 넣었을 때 글자가 잘리거나 다른 라벨과 섞이는 것이
런타임에서 확인되어, 가독성을 우선해 원문 영문을 유지합니다. 대사, 아이템
이름·설명, 일반 시스템 문구 및 위에 집계된 안정적인 그래픽 UI에는 영향을
주지 않습니다.

## 컷씬 자막 수정

- BSCR 문자열을 UTF-8 CJK 별칭 방식으로 다시 빌드했습니다.
- 문자열 풀 뒤의 참조 테이블을 4바이트 단위로 검사해 이동된 포인터
  `37,139`개를 모두 재배치했습니다.
- PPSSPP에서 STG04 컷씬을 직접 재생해 한국어 자막 표시와 `@@@@`
  플레이스홀더 미출력을 확인했습니다.

## 복원

이 패치는 원본을 덮어쓰지 않으므로 복원은 생성된 한국어판 ISO를
제거하는 방식입니다. `Restore-Original.bat` 위에 한국어판 ISO를
끌어다 놓거나 다음 명령을 실행합니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Restore-Original.ps1" -PatchedIso "<한국어판_ISO_경로>"
```

복원 스크립트는 크기와 SHA-256이 완성본과 모두 일치하는 파일만
삭제합니다. 수정되었거나 알 수 없는 파일은 삭제하지 않습니다.

## 무결성 확인

```powershell
Get-Content ".\CHECKSUMS.sha256"
Get-FileHash ".\BRS_Korean_NPUH10126_v1.0.brspatch" -Algorithm SHA256
```

패치 파일:

- 크기: `39,494,639`바이트
- SHA-256: `d42ef76ca9c8ca37b2f449b63e74e4434d8caf1afe0dd32473777a0835ef5b89`

## 검수 상태

- 번역 항목: `3,395`개
- 언어 릴리스 게이트: 통과
- 그래픽 UI 독립 시각 감사: 통과 (`27`개 PTMD)
- 그래픽 UI 게임 컨테이너 통합: 통과 (`9`개)
- PPSSPP QA: 통과
- PPSSPP 부팅 표식: 확인
- 런타임 오류: `0`
- 컷씬 한국어 자막: 확인
- `@@@@` 플레이스홀더: 미출력 확인

세부 사항은 `REPORTS` 디렉터리의 경로 정리된 JSON 보고서를 확인하세요.
