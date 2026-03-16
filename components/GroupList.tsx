"use client";

export type GroupListItem = {
  id: string;
  name: string;
  menu: string;
  creatorName: string;
  memberCount: number;
  hasLink: boolean;
  hasImage: boolean;
  isJoined: boolean;
  canDelete: boolean;
};

type GroupListProps = {
  groups: GroupListItem[];
  onSelect: (groupId: string) => void;
  onDelete: (groupId: string) => Promise<void>;
  deletingGroupId: string | null;
  copy: {
    emptyTitle: string;
    emptyDescription: string;
    fallbackName: string;
    myGroup: string;
    createdBy: string;
    menu: string;
    link: string;
    photo: string;
    delete: string;
  };
};

function LinkIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4"
      fill="none"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      viewBox="0 0 24 24"
    >
      <path d="M10 13a5 5 0 0 0 7.07 0l2.83-2.83a5 5 0 0 0-7.07-7.07L11 4" />
      <path d="M14 11a5 5 0 0 0-7.07 0L4.1 13.83a5 5 0 1 0 7.07 7.07L13 19" />
    </svg>
  );
}

function ImageIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-4 w-4"
      fill="none"
      stroke="currentColor"
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth="2"
      viewBox="0 0 24 24"
    >
      <rect height="16" rx="2" ry="2" width="18" x="3" y="4" />
      <circle cx="8.5" cy="9.5" r="1.5" />
      <path d="m21 15-5-5L5 21" />
    </svg>
  );
}

export default function GroupList({
  groups,
  onSelect,
  onDelete,
  deletingGroupId,
  copy
}: GroupListProps) {
  if (groups.length === 0) {
    return (
      <div className="panel rounded-[1.75rem] p-6 text-center">
        <p className="display-font text-2xl font-semibold text-pine">{copy.emptyTitle}</p>
        <p className="mt-2 text-sm leading-6 text-slate-600">{copy.emptyDescription}</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {groups.map((group) => (
        <div
          className="panel w-full rounded-[1.75rem] p-4 transition hover:-translate-y-0.5 hover:bg-white/90"
          key={group.id}
        >
          <div className="flex items-start justify-between gap-3">
            <button
              className="min-w-0 flex-1 text-left"
              onClick={() => onSelect(group.id)}
              type="button"
            >
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="display-font truncate text-2xl font-semibold text-ink">
                  {group.name || copy.fallbackName}
                </h3>
                {group.isJoined ? (
                  <span className="rounded-full bg-pine/10 px-2.5 py-1 text-xs font-semibold text-pine">
                    {copy.myGroup}
                  </span>
                ) : null}
              </div>

              <p className="mt-2 flex items-baseline gap-2 text-base">
                <span className="text-sm font-semibold uppercase tracking-[0.16em] text-slate-500">
                  {copy.menu}
                </span>
                <span className="font-medium text-slate-800">{group.menu}</span>
              </p>
              <p className="mt-2 text-sm text-slate-600">
                {copy.createdBy} {group.creatorName}
              </p>
            </button>

            <div className="flex flex-col items-end gap-2">
              <div className="rounded-full bg-white/80 px-4 py-2 text-lg font-semibold leading-none text-pine">
                {group.memberCount}
              </div>

              {group.canDelete ? (
                <button
                  className="rounded-full border border-red-200 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60"
                  disabled={deletingGroupId === group.id}
                  onClick={() => void onDelete(group.id)}
                  type="button"
                >
                  {copy.delete}
                </button>
              ) : null}
            </div>
          </div>

          <div className="mt-4 flex items-center gap-3 text-sm text-slate-600">
            {group.hasLink ? (
              <span className="inline-flex items-center gap-1 rounded-full bg-white/80 px-2.5 py-1">
                <LinkIcon />
                {copy.link}
              </span>
            ) : null}
            {group.hasImage ? (
              <span className="inline-flex items-center gap-1 rounded-full bg-white/80 px-2.5 py-1">
                <ImageIcon />
                {copy.photo}
              </span>
            ) : null}
          </div>
        </div>
      ))}
    </div>
  );
}
