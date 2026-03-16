import type { AppLanguage } from "@/hooks/useLanguage";

export const appCopy = {
  ko: {
    loadingTitle: "점심 그룹",
    loadingSubtitle: "실시간 정보를 불러오는 중입니다...",
    communityLabel: "큰사랑교회 공동체",
    appTitle: "점심 그룹",
    share: "공유",
    yourName: "내 이름",
    setDisplayName: "이름을 입력해 주세요",
    dateLabel: "날짜",
    notConfigured: "설정되지 않음",
    joinedHint: "이미 점심 모임에 참여 중입니다. 카드를 눌러 상세 정보를 보거나 다른 모임으로 옮길 수 있습니다.",
    noMembershipHint: "아직 모임에 참여하지 않았습니다. 새 모임을 만들거나 기존 모임에 참여해 보세요.",
    noActiveSession: "meta/currentSession에 활성 세션이 없습니다.",
    openGroups: "모임 목록",
    qr: "QR",
    createGroup: "모임 만들기",
    createGroupDisabled: "현재 주일 날짜를 보고 있을 때만 새 모임을 만들 수 있습니다.",
    languageToggle: "언어 변경",
    sessionBrowser: {
      title: "이전 기록",
      show: "SHOW",
      hide: "HIDE",
      monthLabel: "월 선택",
      sundayLabel: "주일",
      currentBadge: "이번 주",
      archiveBadge: "지난 기록",
      empty: "선택한 달에는 주일 날짜가 없습니다.",
      activeDescription: "현재 주일 세션입니다. 모임 생성과 참여 변경이 가능합니다.",
      archiveDescription: "지난 주일 기록입니다. 이 날짜의 모임 목록과 참여자를 읽기 전용으로 볼 수 있습니다."
    },
    nameGate: {
      title: "이름 입력",
      description: "이번 주 점심 모임에서 다른 사람들에게 보여질 이름을 입력해 주세요.",
      label: "표시 이름",
      placeholder: "예: 김은혜",
      saving: "저장 중...",
      continue: "계속"
    },
    createModal: {
      title: "모임 만들기",
      groupName: "모임 이름",
      groupNamePlaceholder: "선택 입력",
      menu: "메뉴",
      menuPlaceholder: "필수 입력",
      linkUrl: "링크 URL",
      linkUrlPlaceholder: "식당 링크가 있다면 입력",
      image: "사진",
      imageHelp: "현재 세션의 Firebase Storage에 저장됩니다.",
      helper: "모임을 만들면 자동으로 해당 모임에 참여합니다. 기존에 참여 중인 모임이 있으면 새 모임으로 바뀝니다.",
      creating: "만드는 중...",
      submit: "모임 만들기"
    },
    groupList: {
      emptyTitle: "아직 모임이 없습니다",
      emptyDescription: "이 날짜에 등록된 점심 모임이 없습니다.",
      fallbackName: "점심 모임",
      myGroup: "내 모임",
      createdBy: "만든 사람",
      link: "링크",
      photo: "사진"
    },
    detailModal: {
      menuLabel: "메뉴",
      createdBy: "만든 사람",
      members: "참여자",
      noMembers: "아직 참여한 사람이 없습니다.",
      leaveGroup: "모임 나가기",
      moveToGroup: "이 모임으로 이동",
      joinGroup: "모임 참여하기",
      leaveCurrentGroup: "현재 모임 나가기",
      working: "처리 중...",
      archiveNotice: "지난 세션은 읽기 전용입니다. 현재 주일 세션에서만 참여를 바꿀 수 있습니다."
    },
    shareModal: {
      title: "앱 공유",
      description: "QR 코드를 스캔하면 이번 주 점심 모임 페이지를 바로 열 수 있습니다.",
      generating: "QR 코드를 만드는 중...",
      qrAlt: "앱 공유용 QR 코드",
      copyLink: "링크 복사",
      copied: "링크가 복사되었습니다",
      generateError: "QR 코드를 만들 수 없습니다."
    },
    modal: {
      close: "닫기",
      closeBackdrop: "모달 배경 닫기"
    }
  },
  en: {
    loadingTitle: "Lunch Groups",
    loadingSubtitle: "Loading live updates...",
    communityLabel: "His Great Love Church",
    appTitle: "Lunch Groups",
    share: "Share",
    yourName: "Your name",
    setDisplayName: "Set your display name",
    dateLabel: "Date",
    notConfigured: "Not configured",
    joinedHint: "You are already in a lunch group. Tap any card to view details or switch.",
    noMembershipHint: "You are not in a group yet. Create one or join an existing group.",
    noActiveSession: "No active session found in meta/currentSession.",
    openGroups: "Groups",
    qr: "QR",
    createGroup: "Create group",
    createGroupDisabled: "You can only create a group while viewing the current Sunday.",
    languageToggle: "Change language",
    sessionBrowser: {
      title: "Previous Dates",
      show: "SHOW",
      hide: "HIDE",
      monthLabel: "Month",
      sundayLabel: "Sunday",
      currentBadge: "Current",
      archiveBadge: "Archive",
      empty: "There are no Sunday dates in the selected month.",
      activeDescription: "You are viewing the current Sunday session. Group creation and membership changes are enabled.",
      archiveDescription: "You are viewing an archived Sunday session. Group lists and members are read-only here."
    },
    nameGate: {
      title: "Your name",
      description: "Enter the name you want everyone to see in this week's lunch groups.",
      label: "Display name",
      placeholder: "e.g. Grace Kim",
      saving: "Saving...",
      continue: "Continue"
    },
    createModal: {
      title: "Create group",
      groupName: "Group name",
      groupNamePlaceholder: "Optional name",
      menu: "Menu",
      menuPlaceholder: "Required menu",
      linkUrl: "Link URL",
      linkUrlPlaceholder: "Optional restaurant link",
      image: "Image",
      imageHelp: "Stored in Firebase Storage for the current session.",
      helper: "You automatically join the group after creating it. Creating a new group also replaces your current group membership.",
      creating: "Creating...",
      submit: "Create group"
    },
    groupList: {
      emptyTitle: "No groups yet",
      emptyDescription: "There are no lunch groups saved for this date.",
      fallbackName: "Lunch Group",
      myGroup: "My group",
      createdBy: "Created by",
      link: "Link",
      photo: "Photo"
    },
    detailModal: {
      menuLabel: "Menu",
      createdBy: "Created by",
      members: "Members",
      noMembers: "No one has joined yet.",
      leaveGroup: "Leave group",
      moveToGroup: "Move to group",
      joinGroup: "Join group",
      leaveCurrentGroup: "Leave current group",
      working: "Working...",
      archiveNotice: "Archived sessions are read-only. Change membership only in the current Sunday session."
    },
    shareModal: {
      title: "Share app",
      description: "Let people scan the QR code to open this week's lunch group page.",
      generating: "Generating QR...",
      qrAlt: "QR code for sharing the app",
      copyLink: "Copy link",
      copied: "Link copied",
      generateError: "Could not generate QR code."
    },
    modal: {
      close: "Close",
      closeBackdrop: "Close modal backdrop"
    }
  }
} as const;

export function getCopy(language: AppLanguage) {
  return appCopy[language];
}
