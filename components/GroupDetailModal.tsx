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
  location: string;
  linkUrl: string;
  imageUrl: string;
  creatorId: string;
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
  onDelete: (groupId: string) => Promise<void>;
  onEditLocation: (groupId: string, currentLocation: string) => Promise<void>;
  canEdit: boolean;
  canDelete: boolean;
  canEditLocation: boolean;
  copy: {
    menuLabel: string;
    locationLabel: string;
    createdBy: string;
    members: string;
    memberCountPrefix: string;
    memberCountSuffix: string;
    noMembers: string;
    leaveGroup: string;
    moveToGroup: string;
    joinGroup: string;
    leaveCurrentGroup: string;
    deleteGroup: string;
    editLocation: string;
    addLocation: string;
    deleteConfirm: string;
    working: string;
    fallbackName: string;
    archiveNotice: string;
  };
  modalCopy: {
    close: string;
    closeBackdrop: string;
  };
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
  onLeave,
  onDelete,
  onEditLocation,
  canEdit,
  canDelete,
  canEditLocation,
  copy,
  modalCopy
}: GroupDetailModalProps) {
  if (!group) {
    return null;
  }

  const groupId = group.id;
  const groupLocation = group.location;
  const isCurrentGroup = membershipGroupId === groupId;
  const hasMembership = Boolean(membershipGroupId);
  const primaryLabel = isCurrentGroup
    ? copy.leaveGroup
    : hasMembership
      ? copy.moveToGroup
      : copy.joinGroup;

  function formatMemberCount(memberCount: number) {
    if (copy.memberCountPrefix) {
      return `${copy.memberCountPrefix} ${memberCount}`;
    }

    if (copy.memberCountSuffix) {
      return `${memberCount} ${copy.memberCountSuffix}`;
    }

    return `${memberCount}`;
  }

  async function handlePrimaryAction() {
    if (isCurrentGroup) {
      await onLeave();
      return;
    }

    await onJoin(groupId);
  }

  async function handleDelete() {
    await onDelete(groupId);
  }

  async function handleEditLocation() {
    await onEditLocation(groupId, groupLocation);
  }

  return (
    <Modal
      backdropLabel={modalCopy.closeBackdrop}
      closeLabel={modalCopy.close}
      isOpen={Boolean(group)}
      onClose={onClose}
      title={group.name || copy.fallbackName}
    >
      <div className="space-y-5">
        <div className="rounded-[1.5rem] bg-gradient-to-br from-pine to-moss p-5 text-white">
          <p className="mt-1 flex items-baseline gap-2 text-2xl font-semibold">
            <span className="inline-block w-20 shrink-0 text-sm font-semibold uppercase tracking-[0.22em] text-white/75">
              {copy.menuLabel}
            </span>
            <span>{group.menu}</span>
          </p>
          {group.location ? (
            <p className="mt-3 flex items-baseline gap-2 text-base text-white/90">
              <span className="inline-block w-20 shrink-0 text-sm font-semibold uppercase tracking-[0.22em] text-white/75">
                {copy.locationLabel}
              </span>
              <span>{group.location}</span>
            </p>
          ) : null}
          <p className="mt-3 text-sm text-white/80">
            {copy.createdBy} {group.creatorName}
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
            alt={group.name || copy.fallbackName}
            className="h-56 w-full rounded-[1.5rem] object-cover"
            src={group.imageUrl}
          />
        ) : null}

        <div className="rounded-[1.5rem] bg-white/75 p-4">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-slate-500">
              {copy.members}
            </p>
            <p className="rounded-full bg-pine/10 px-4 py-2 text-base font-semibold text-pine">
              {formatMemberCount(group.members.length)}
            </p>
          </div>

          <div className="mt-4 space-y-2">
            {group.members.length === 0 ? (
              <p className="text-sm text-slate-600">{copy.noMembers}</p>
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

        {canEdit ? (
          <div className="grid grid-cols-1 gap-3">
            <button
              className="rounded-[1.4rem] bg-pine px-4 py-4 text-base font-semibold text-white transition hover:bg-pine/90 disabled:cursor-not-allowed disabled:bg-pine/50"
              disabled={isBusy}
              onClick={handlePrimaryAction}
              type="button"
            >
              {isBusy ? copy.working : primaryLabel}
            </button>

            {canDelete ? (
              <button
                className="rounded-[1.4rem] border border-red-200 bg-red-50 px-4 py-4 text-base font-semibold text-red-700 transition hover:bg-red-100 disabled:cursor-not-allowed disabled:opacity-60"
                disabled={isBusy}
                onClick={handleDelete}
                type="button"
              >
                {copy.deleteGroup}
              </button>
            ) : null}

            {canEditLocation ? (
              <button
                className="rounded-[1.4rem] border border-pine/15 bg-white/80 px-4 py-4 text-base font-semibold text-pine transition hover:bg-pine/5 disabled:cursor-not-allowed disabled:opacity-60"
                disabled={isBusy}
                onClick={handleEditLocation}
                type="button"
              >
                {groupLocation ? copy.editLocation : copy.addLocation}
              </button>
            ) : null}
          </div>
        ) : (
          <div className="rounded-[1.4rem] bg-sand/70 px-4 py-4 text-sm leading-6 text-slate-600">
            {copy.archiveNotice}
          </div>
        )}
      </div>
    </Modal>
  );
}
