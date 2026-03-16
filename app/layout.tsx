import type { Metadata } from "next";
import { Noto_Sans_KR } from "next/font/google";
import type { ReactNode } from "react";
import "./globals.css";

const notoSansKr = Noto_Sans_KR({
  preload: false,
  variable: "--font-body-ko",
  weight: ["400", "500", "600", "700"]
});

export const metadata: Metadata = {
  title: "Sunday Lunch Groups",
  description: "Mobile-first lunch group organizer for a small church community."
};

export default function RootLayout({
  children
}: Readonly<{
  children: ReactNode;
}>) {
  return (
    <html lang="ko">
      <body className={notoSansKr.variable}>
        {children}
      </body>
    </html>
  );
}
