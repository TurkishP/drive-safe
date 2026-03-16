"use client";

import {
  collection,
  getDocs,
  doc,
  onSnapshot,
  query,
  serverTimestamp,
  where,
  writeBatch
} from "firebase/firestore";
import {
  getDownloadURL,
  ref as storageRef,
  uploadBytes
} from "firebase/storage";
import { getFirebaseDb, getFirebaseStorage } from "@/lib/firebase";

export type LunchGroup = {
  id: string;
  name: string;
  menu: string;
  linkUrl: string;
  imageUrl: string;
  creatorId: string;
  status: string;
  createdAt: Date | null;
};

type CreateGroupInput = {
  sessionId: string;
  creatorId: string;
  menu: string;
  name?: string;
  linkUrl?: string;
  imageFile?: File | null;
};

function normalizeFileName(fileName: string) {
  return fileName.replace(/[^a-zA-Z0-9._-]/g, "-");
}

export function subscribeGroups(
  sessionId: string,
  onData: (groups: Record<string, LunchGroup>) => void,
  onError?: (message: string) => void
) {
  return onSnapshot(
    collection(getFirebaseDb(), "sessions", sessionId, "groups"),
    (snapshot) => {
      const nextGroups: Record<string, LunchGroup> = {};

      snapshot.forEach((groupDoc) => {
        const data = groupDoc.data();
        nextGroups[groupDoc.id] = {
          id: groupDoc.id,
          name: data.name ?? "",
          menu: data.menu ?? "",
          linkUrl: data.linkUrl ?? "",
          imageUrl: data.imageUrl ?? "",
          creatorId: data.creatorId ?? "",
          status: data.status ?? "open",
          createdAt: data.createdAt?.toDate?.() ?? null
        };
      });

      onData(nextGroups);
    },
    (error) => {
      onError?.(error.message);
    }
  );
}

export async function createGroup({
  sessionId,
  creatorId,
  menu,
  name,
  linkUrl,
  imageFile
}: CreateGroupInput) {
  const db = getFirebaseDb();
  const storage = getFirebaseStorage();
  const groupRef = doc(collection(db, "sessions", sessionId, "groups"));
  let imageUrl = "";

  if (imageFile) {
    const filePath = `sessions/${sessionId}/groupImages/${creatorId}/${Date.now()}-${normalizeFileName(
      imageFile.name
    )}`;
    const uploadedImageRef = storageRef(storage, filePath);
    await uploadBytes(uploadedImageRef, imageFile);
    imageUrl = await getDownloadURL(uploadedImageRef);
  }

  const batch = writeBatch(db);

  batch.set(groupRef, {
    name: name?.trim() ?? "",
    menu: menu.trim(),
    linkUrl: linkUrl?.trim() ?? "",
    imageUrl,
    creatorId,
    status: "open",
    createdAt: serverTimestamp()
  });

  batch.set(doc(db, "sessions", sessionId, "memberships", creatorId), {
    participantId: creatorId,
    groupId: groupRef.id,
    joinedAt: serverTimestamp()
  });

  await batch.commit();
  return groupRef.id;
}

export async function deleteGroup(sessionId: string, groupId: string) {
  const db = getFirebaseDb();
  const membershipsRef = collection(db, "sessions", sessionId, "memberships");
  const membershipsSnapshot = await getDocs(
    query(membershipsRef, where("groupId", "==", groupId))
  );
  const batch = writeBatch(db);

  membershipsSnapshot.forEach((membershipDoc) => {
    batch.delete(membershipDoc.ref);
  });

  batch.delete(doc(db, "sessions", sessionId, "groups", groupId));
  await batch.commit();
}
