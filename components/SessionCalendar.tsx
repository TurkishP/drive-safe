"use client";

type SessionCalendarProps = {
  monthValue: string;
  sessionIds: string[];
  selectedSessionId: string | null;
  activeSessionId: string | null;
  onMonthChange: (monthValue: string) => void;
  onSessionSelect: (sessionId: string) => void;
  copy: {
    title: string;
    monthLabel: string;
    sundayLabel: string;
    currentBadge: string;
    archiveBadge: string;
    empty: string;
    activeDescription: string;
    archiveDescription: string;
  };
  formatSessionDate: (sessionId: string) => string;
  formatShortSessionDate: (sessionId: string) => string;
};

export default function SessionCalendar({
  monthValue,
  sessionIds,
  selectedSessionId,
  activeSessionId,
  onMonthChange,
  onSessionSelect,
  copy,
  formatSessionDate,
  formatShortSessionDate
}: SessionCalendarProps) {
  const isViewingActiveSession =
    Boolean(selectedSessionId) && selectedSessionId === activeSessionId;

  return (
    <section className="panel rounded-[1.75rem] p-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500">
            {copy.monthLabel}
          </p>
          <h2 className="display-font mt-2 text-2xl font-semibold text-ink">
            {copy.title}
          </h2>
        </div>

        <input
          className="rounded-2xl border border-pine/15 bg-white/90 px-4 py-3 text-sm font-semibold text-slate-700 outline-none transition focus:border-pine focus:ring-2 focus:ring-pine/15"
          onChange={(event) => onMonthChange(event.target.value)}
          type="month"
          value={monthValue}
        />
      </div>

      {sessionIds.length === 0 ? (
        <p className="mt-4 rounded-[1.35rem] bg-white/75 px-4 py-4 text-sm text-slate-600">
          {copy.empty}
        </p>
      ) : (
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
          {sessionIds.map((sessionId) => {
            const isSelected = sessionId === selectedSessionId;
            const isActive = sessionId === activeSessionId;

            return (
              <button
                className={`rounded-[1.45rem] border px-4 py-4 text-left transition ${
                  isSelected
                    ? "border-pine bg-pine text-white shadow-soft"
                    : "border-pine/10 bg-white/80 text-slate-700 hover:bg-pine/5"
                }`}
                key={sessionId}
                onClick={() => onSessionSelect(sessionId)}
                type="button"
              >
                <p
                  className={`text-xs font-semibold uppercase tracking-[0.18em] ${
                    isSelected ? "text-white/75" : "text-slate-500"
                  }`}
                >
                  {copy.sundayLabel}
                </p>
                <p className="mt-2 text-lg font-semibold">
                  {formatShortSessionDate(sessionId)}
                </p>
                <p
                  className={`mt-1 text-xs ${
                    isSelected ? "text-white/75" : "text-slate-500"
                  }`}
                >
                  {formatSessionDate(sessionId)}
                </p>
                <span
                  className={`mt-3 inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                    isSelected
                      ? "bg-white/15 text-white"
                      : isActive
                        ? "bg-ember/15 text-ember"
                        : "bg-slate-100 text-slate-600"
                  }`}
                >
                  {isActive ? copy.currentBadge : copy.archiveBadge}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {selectedSessionId ? (
        <div className="mt-4 rounded-[1.4rem] bg-gradient-to-r from-ember/15 to-moss/15 px-4 py-4 text-sm text-slate-700">
          {isViewingActiveSession
            ? copy.activeDescription
            : copy.archiveDescription}
        </div>
      ) : null}
    </section>
  );
}
