"use client";

import { useEffect, useState, type FormEvent } from "react";
import Modal from "@/components/Modal";

type CreateGroupValues = {
  name: string;
  menu: string;
  location: string;
  linkUrl: string;
  imageFile: File | null;
};

type CreateGroupModalProps = {
  isOpen: boolean;
  isSubmitting: boolean;
  onClose: () => void;
  onSubmit: (values: CreateGroupValues) => Promise<void>;
  copy: {
    title: string;
    groupName: string;
    groupNamePlaceholder: string;
    menu: string;
    menuPlaceholder: string;
    location: string;
    locationPlaceholder: string;
    linkUrl: string;
    linkUrlPlaceholder: string;
    image: string;
    imageHelp: string;
    helper: string;
    creating: string;
    submit: string;
  };
  modalCopy: {
    close: string;
    closeBackdrop: string;
  };
};

export default function CreateGroupModal({
  isOpen,
  isSubmitting,
  onClose,
  onSubmit,
  copy,
  modalCopy
}: CreateGroupModalProps) {
  const [name, setName] = useState("");
  const [menu, setMenu] = useState("");
  const [location, setLocation] = useState("");
  const [linkUrl, setLinkUrl] = useState("");
  const [imageFile, setImageFile] = useState<File | null>(null);

  useEffect(() => {
    if (isOpen) {
      return;
    }

    setName("");
    setMenu("");
    setLocation("");
    setLinkUrl("");
    setImageFile(null);
  }, [isOpen]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!menu.trim()) {
      return;
    }

    await onSubmit({
      name,
      menu,
      location,
      linkUrl,
      imageFile
    });
  }

  return (
    <Modal
      backdropLabel={modalCopy.closeBackdrop}
      closeLabel={modalCopy.close}
      isOpen={isOpen}
      onClose={onClose}
      title={copy.title}
    >
      <form className="space-y-4" onSubmit={handleSubmit}>
        <label className="block space-y-2">
          <span className="text-sm font-semibold text-slate-700">{copy.groupName}</span>
          <input
            className="w-full rounded-2xl border border-pine/15 bg-white/90 px-4 py-3 outline-none transition focus:border-pine focus:ring-2 focus:ring-pine/15"
            onChange={(event) => setName(event.target.value)}
            placeholder={copy.groupNamePlaceholder}
            value={name}
          />
        </label>

        <label className="block space-y-2">
          <span className="text-sm font-semibold text-slate-700">{copy.menu}</span>
          <input
            className="w-full rounded-2xl border border-pine/15 bg-white/90 px-4 py-3 outline-none transition focus:border-pine focus:ring-2 focus:ring-pine/15"
            onChange={(event) => setMenu(event.target.value)}
            placeholder={copy.menuPlaceholder}
            required
            value={menu}
          />
        </label>

        <label className="block space-y-2">
          <span className="text-sm font-semibold text-slate-700">{copy.location}</span>
          <input
            className="w-full rounded-2xl border border-pine/15 bg-white/90 px-4 py-3 outline-none transition focus:border-pine focus:ring-2 focus:ring-pine/15"
            onChange={(event) => setLocation(event.target.value)}
            placeholder={copy.locationPlaceholder}
            value={location}
          />
        </label>

        <label className="block space-y-2">
          <span className="text-sm font-semibold text-slate-700">{copy.linkUrl}</span>
          <input
            className="w-full rounded-2xl border border-pine/15 bg-white/90 px-4 py-3 outline-none transition focus:border-pine focus:ring-2 focus:ring-pine/15"
            onChange={(event) => setLinkUrl(event.target.value)}
            placeholder={copy.linkUrlPlaceholder}
            type="url"
            value={linkUrl}
          />
        </label>

        <label className="block space-y-2">
          <span className="text-sm font-semibold text-slate-700">{copy.image}</span>
          <input
            accept="image/*"
            className="w-full rounded-2xl border border-dashed border-pine/20 bg-white/70 px-4 py-3 text-sm"
            onChange={(event) => {
              setImageFile(event.target.files?.[0] ?? null);
            }}
            type="file"
          />
          <span className="block text-xs text-slate-500">{copy.imageHelp}</span>
        </label>

        <div className="rounded-[1.4rem] bg-sand/70 px-4 py-3 text-sm leading-6 text-slate-600">
          {copy.helper}
        </div>

        <button
          className="w-full rounded-[1.4rem] bg-ember px-4 py-4 text-base font-semibold text-white transition hover:bg-ember/90 disabled:cursor-not-allowed disabled:bg-ember/50"
          disabled={isSubmitting || !menu.trim()}
          type="submit"
        >
          {isSubmitting ? copy.creating : copy.submit}
        </button>
      </form>
    </Modal>
  );
}
