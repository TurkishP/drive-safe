import type { AppLanguage } from "@/hooks/useLanguage";

function pad(value: number) {
  return `${value}`.padStart(2, "0");
}

export function parseSessionId(sessionId: string) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(sessionId);

  if (!match) {
    return null;
  }

  return {
    year: Number(match[1]),
    month: Number(match[2]),
    day: Number(match[3])
  };
}

export function formatSessionId(sessionId: string, language: AppLanguage) {
  const parsed = parseSessionId(sessionId);

  if (!parsed) {
    return sessionId;
  }

  if (language === "ko") {
    return `${parsed.year}.${pad(parsed.month)}.${pad(parsed.day)}`;
  }

  return `${parsed.year}.${pad(parsed.month)}.${pad(parsed.day)}`;
}

export function formatShortSessionId(sessionId: string) {
  const parsed = parseSessionId(sessionId);

  if (!parsed) {
    return sessionId;
  }

  return `${pad(parsed.month)}.${pad(parsed.day)}`;
}

export function getMonthValueFromSessionId(sessionId: string) {
  const parsed = parseSessionId(sessionId);

  if (!parsed) {
    return "";
  }

  return `${parsed.year}-${pad(parsed.month)}`;
}

export function getTodayMonthValue() {
  const now = new Date();
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}`;
}

export function getSundaySessionIdsForMonth(monthValue: string) {
  const match = /^(\d{4})-(\d{2})$/.exec(monthValue);

  if (!match) {
    return [];
  }

  const year = Number(match[1]);
  const month = Number(match[2]) - 1;
  const firstDay = new Date(year, month, 1, 12);
  const lastDay = new Date(year, month + 1, 0, 12);
  const sundays: string[] = [];

  for (let day = new Date(firstDay); day <= lastDay; day.setDate(day.getDate() + 1)) {
    if (day.getDay() === 0) {
      sundays.push(
        `${day.getFullYear()}-${pad(day.getMonth() + 1)}-${pad(day.getDate())}`
      );
    }
  }

  return sundays;
}
