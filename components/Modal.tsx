"use client";

import { useEffect, type ReactNode } from "react";

type ModalProps = {
  isOpen: boolean;
  title: string;
  children: ReactNode;
  onClose: () => void;
  dismissible?: boolean;
  closeLabel?: string;
  backdropLabel?: string;
  titleClassName?: string;
};

export default function Modal({
  isOpen,
  title,
  children,
  onClose,
  dismissible = true,
  closeLabel = "Close",
  backdropLabel = "Close modal backdrop",
  titleClassName
}: ModalProps) {
  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const handleEscape = (event: KeyboardEvent) => {
      if (event.key === "Escape" && dismissible) {
        onClose();
      }
    };

    window.addEventListener("keydown", handleEscape);
    return () => {
      window.removeEventListener("keydown", handleEscape);
    };
  }, [dismissible, isOpen, onClose]);

  if (!isOpen) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-slate-950/50 px-4 pb-4 pt-16 backdrop-blur-sm sm:items-center">
      <button
        aria-label={backdropLabel}
        className="absolute inset-0"
        disabled={!dismissible}
        onClick={dismissible ? onClose : undefined}
        type="button"
      />

      <div className="panel-strong relative z-10 flex max-h-[88vh] w-full max-w-lg flex-col overflow-hidden rounded-[2rem]">
        <div className="flex items-center justify-between border-b border-pine/10 px-5 py-4">
          <h2 className={`display-font min-w-0 pr-3 font-semibold text-pine ${titleClassName ?? "text-2xl"}`}>
            {title}
          </h2>

          {dismissible ? (
            <button
              className="rounded-full border border-pine/15 px-3 py-2 text-sm font-semibold text-pine transition hover:bg-pine/5"
              onClick={onClose}
              type="button"
            >
              {closeLabel}
            </button>
          ) : null}
        </div>

        <div className="overflow-y-auto px-5 py-5">{children}</div>
      </div>
    </div>
  );
}
