# 검증 보고서 안내

## 현재 커밋 후보에 직접 대응하는 보고서

- `current_candidate_qa.json`: 현 후보의 빌드·패치·설치·패키징 상태
- `release_build_report.json`: 누적 ISO/BRSPATCH 빌드 결과
- `language_release_gate_report.json`: 4,777항목 번역 릴리스 게이트
- `font_verification.json`: 폰트 및 UCS2/JIS 매핑 검증
- `powershell_patcher_test_report.json`: 현재 패치의 PowerShell 왕복 설치 검증
- `alien_name_reversion_final_validation.json`: 외계인 고유명 라틴 표기 복원 감사
- `stage_saha_cleanup_qa.json`: 4x 테스트 아틀라스 SAHA 잔여 픽셀 제거 감사
- `release_hd_stage_atlas_qa.json`: 배포용 8x HD 아틀라스 감사
- `hd_ui_pack_report.json`: 선택 설치 HD UI 팩 요약
- `ppsspp_final_qa_report.json`: 현재 대상의 런타임 스모크 상태

## 역사적 참고 자료

`language_audits`, `ui_graphics`, `ppsspp_evidence`,
`CUTSCENE_AND_MENU_FIX_HANDOFF.md`, `governor_term_correction_report.json`은
이전 단계에서 만든 감사 및 조사 자료입니다. 특히 과거 `ui_graphics` 보고서의
모든 그래픽 UI를 ISO에 직접 넣는 방식은 현재 배포 정책이 아닙니다. 현재 정책은
고정 메뉴 그래픽을 ISO에서는 영어로 유지하고, 고해상도 한국어 UI를 별도 선택
팩으로 제공하는 것입니다.

현재 대상 SHA-256은 PPSSPP `v1.20.4`에서 새로 부팅·플레이·정상 종료를
확인했습니다. 과거 스크린샷과 실행 로그는 현재 후보의 증거와 구분합니다.
