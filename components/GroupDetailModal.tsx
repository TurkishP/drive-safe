"use client";

import Modal from "@/components/Modal";

type GroupMember = {
  id: string;
  displayName: string;
};

type GroupDetail = {
  id: string;
  name: string;
  menu: string;
  linkUrl: string;
  imageUrl: string;
  creatorName: string;
  members: GroupMember[];
};

type GroupDetailModalProps = {
  group: GroupDetail | null;
  membershipGroupId: string | null;
  isBusy: boolean;
  onClose: () => void;
  onJoin: (groupId: string) => Promise<void>;
  onLeave: () => Promise<void>;
};

function ExternalLinkIcon() {
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
      <path d="M14 3h7v7" />
      <path d="M10 14 21 3" />
      <path d="M21 14v4a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3h4" />
    </svg>
  );
}

export default function GroupDetailModal({
  group,
  membershipGroupId,
  isBusy,
  onClose,
  onJoin,
  onLeave
}: GroupDetailModalProps) {
  if (!group) {
    return null;
  }

  const groupId = group.id;
  const isCurrentGroup = membershipGroupId === groupId;
  const hasMembership = Boolean(membershipGroupId);
  const primaryLabel = isCurrentGroup
    ? "Leave group"
    : hasMembership
      ? "Move to group"
      : "Join group";

  async function handlePrimaryAction() {
    if (isCurrentGroup) {
      await onLeave();
      return;
    }

    await onJoin(groupId);
  }

  return (
    <Modal isOpen={Boolean(group)} onClose={onClose} title={group.name || "Lunch Group"}>
      <div className="space-y-5">
        <div className="rounded-[1.5rem] bg-gradient-to-br from-pine to-moss p-5 text-white">
          <p className="text-sm uppercase tracking-[0.22em] text-white/75">
            Today&apos;s Menu
          </p>
          <p className="mt-2 text-2xl font-semibold">{group.menu}</p>
          <p className="mt-3 text-sm text-white/80">
            Created by {group.creatorName}
          </p>
        </div>

        {group.linkUrl ? (
          <a
            className="flex items-center justify-between rounded-[1.4rem] border border-pine/10 bg-white/80 px-4 py-4 text-sm font-semibold text-pine"
            href={group.linkUrl}
            rel="noreferrer"
            target="_blank"
          >
            <span className="truncate pr-3">{group.linkUrl}</span>
            <ExternalLinkIcon />
          </a>
        ) : null}

        {group.imageUrl ? (
          <img
            alt={group.name || "Group preview"}
            className="h-56 w-full rounded-[1.5rem] object-cover"
            src={group.imageUrl}
          />
        ) : null}

        <div className="rounded-[1.5rem] bg-white/75 p-4">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
              Members
            </p>
            <p className="rounded-full bg-pine/10 px-3 py-1 text-sm font-semibold text-pine">
              {group.members.length}
            </p>
          </div>

          <div className="mt-4 space-y-2">
            {group.members.length === 0 ? (
              <p className="text-sm text-slate-600">No one has joined yet.</p>
            ) : (
              group.members.map((member) => (
                <div
                  className="flex items-center justify-between rounded-2xl border border-pine/10 bg-white/90 px-4 py-3"
                  key={member.id}
                >
                  <span className="font-medium text-slate-800">
                    {member.displayName}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <button
            className="rounded-[1.4rem] bg-pine px-4 py-4 text-base font-semibold text-white transition hover:bg-pine/90 disabled:cursor-not-allowed disabled:bg-pine/50"
            disabled={isBusy}
            onClick={handlePrimaryAction}
            type="button"
          >
            {isBusy ? "Working..." : primaryLabel}
          </button>

          {!isCurrentGroup && membershipGroupId ? (
            <button
              className="rounded-[1.4rem] border border-pine/15 bg-white/80 px-4 py-4 text-base font-semibold text-pine transition hover:bg-pine/5 disabled:cursor-not-allowed disabled:opacity-60"
              disabled={isBusy}
              onClick={onLeave}
              type="button"
            >
              Leave current group
            </button>
          ) : null}
        </div>
      </div>
    </Modal>
  );
}
