# Gemini 2.0 Flash チャットアプリケーション

このプロジェクトは、Google Cloud Platform (GCP) 上で動作する Gemini 2.0 Flash API を活用したチャットボットアプリケーションです。OAuth 2.0 認証、シークレット管理、そして安全なAPIキー管理を実装しています。

## 目次

1. [プロジェクト概要](#プロジェクト概要)
2. [機能一覧](#機能一覧)
3. [技術スタック](#技術スタック)
4. [アーキテクチャ](#アーキテクチャ)
5. [セットアップ手順](#セットアップ手順)
6. [OAuth 2.0 実装ガイド](#oauth-20-実装ガイド)
7. [CORS 対応ガイド](#cors-対応ガイド)
8. [シークレット管理](#シークレット管理)
9. [デプロイ手順](#デプロイ手順)
10. [トラブルシューティング](#トラブルシューティング)

## プロジェクト概要

このアプリケーションは、Gemini 2.0 Flash API を使用したチャットボットを提供し、ユーザーが AI モデルと対話できる環境を構築します。また、シークレット管理機能により、API キーやモデルデータが適切に保存されているかを確認できます。

## 機能一覧

- **チャットインターフェース**: Gemini 2.0 Flash API を使用した対話型チャット
- **OAuth 2.0 認証**: Google アカウントを使用したセキュアなログイン
- **シークレット管理**: API キーとモデルデータの管理状態確認
- **レスポンシブデザイン**: モバイルからデスクトップまで対応したUI

## 技術スタック

- **フロントエンド**: Next.js, React, Tailwind CSS
- **バックエンド**: Next.js API Routes
- **認証**: NextAuth.js (OAuth 2.0)
- **AI モデル**: Gemini 2.0 Flash API
- **デプロイ**: Docker, Google Cloud Run
- **シークレット管理**: GCP Secret Manager (または環境変数)

## アーキテクチャ

```
クライアント <-> Next.js サーバー <-> Gemini API
    |               |
    |               v
    |          Secret Manager
    v
Google OAuth
```

- クライアントからのリクエストは Next.js サーバーで処理
- 認証は NextAuth.js を通じて Google OAuth で実施
- チャットメッセージは Gemini API に転送され、レスポンスを取得
- API キーは環境変数または Secret Manager で安全に管理

## セットアップ手順

### 前提条件

- Node.js 16.x 以上
- npm または yarn
- Google Cloud アカウント
- GitHub アカウント

### ローカル開発環境のセットアップ

1. リポジトリのクローン:

```bash
git clone https://github.com/tsubouchi/gemini-flash-chat.git
cd gemini-flash-chat
```

2. 依存関係のインストール:

```bash
npm install
```

3. 環境変数の設定:

`.env.local` ファイルを作成し、以下の内容を設定:

```
NEXT_PUBLIC_GEMINI_API_KEY=あなたのGemini APIキー
GOOGLE_CLIENT_ID=あなたのGoogleクライアントID
GOOGLE_CLIENT_SECRET=あなたのGoogleクライアントシークレット
NEXTAUTH_SECRET=ランダムな文字列
NEXTAUTH_URL=http://localhost:3000
```

4. 開発サーバーの起動:

```bash
npm run dev
```

5. ブラウザで `http://localhost:3000` にアクセス

## OAuth 2.0 実装ガイド

OAuth 2.0 認証は NextAuth.js を使用して実装しています。以下に実装のポイントと注意点を説明します。

### 1. NextAuth.js のセットアップ

NextAuth.js は React アプリケーションに認証機能を簡単に追加できるライブラリです。

#### インストール

```bash
npm install next-auth
```

#### 基本設定 (`pages/api/auth/[...nextauth].ts`)

```typescript
import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';

export default NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
    }),
  ],
  secret: process.env.NEXTAUTH_SECRET,
  session: {
    strategy: 'jwt',
    maxAge: 30 * 24 * 60 * 60, // 30日
  },
  callbacks: {
    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.sub as string;
      }
      return session;
    },
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
  },
});
```

### 2. Google OAuth の設定手順

1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを作成または選択
3. 「APIとサービス」>「認証情報」に移動
4. 「認証情報を作成」>「OAuth クライアント ID」を選択
5. アプリケーションタイプとして「ウェブアプリケーション」を選択
6. 名前を入力（例: "Gemini Chat Auth"）
7. 承認済みリダイレクト URI に以下を追加:
   - 開発環境: `http://localhost:3000/api/auth/callback/google`
   - 本番環境: `https://あなたのドメイン/api/auth/callback/google`
8. 「作成」をクリックし、表示される「クライアントID」と「クライアントシークレット」を保存

### 3. SessionProvider の設定 (`_app.tsx`)

アプリケーション全体で認証状態を共有するために SessionProvider を設定します:

```typescript
import { SessionProvider } from 'next-auth/react';
import '../styles/globals.css';
import type { AppProps } from 'next/app';

function MyApp({ Component, pageProps: { session, ...pageProps } }: AppProps) {
  return (
    <SessionProvider session={session}>
      <Component {...pageProps} />
    </SessionProvider>
  );
}

export default MyApp;
```

### 4. 認証状態の利用

コンポーネント内で認証状態を利用する方法:

```typescript
import { useSession, signIn, signOut } from 'next-auth/react';

export default function Component() {
  const { data: session, status } = useSession();
  const loading = status === 'loading';
  
  if (loading) {
    return <div>Loading...</div>;
  }
  
  if (!session) {
    return (
      <div>
        <p>ログインしていません</p>
        <button onClick={() => signIn()}>ログイン</button>
      </div>
    );
  }
  
  return (
    <div>
      <p>ログイン中: {session.user?.name}</p>
      <button onClick={() => signOut()}>ログアウト</button>
    </div>
  );
}
```

### 5. 保護されたルートの作成

特定のページを認証ユーザーのみがアクセスできるようにする方法:

```typescript
import { useSession } from 'next-auth/react';
import { useRouter } from 'next/router';
import { useEffect } from 'react';

export default function ProtectedPage() {
  const { data: session, status } = useSession();
  const router = useRouter();
  
  useEffect(() => {
    if (status === 'loading') return;
    if (!session) router.push('/auth/signin');
  }, [session, status, router]);
  
  if (status === 'loading') {
    return <div>Loading...</div>;
  }
  
  if (!session) {
    return null;
  }
  
  return <div>保護されたコンテンツ</div>;
}
```

### 6. OAuth 2.0 実装のコツと注意点

- **環境変数の管理**: クライアントIDとシークレットは必ず環境変数で管理し、ソースコードにハードコーディングしない
- **HTTPS の使用**: 本番環境では必ずHTTPSを使用する
- **スコープの最小化**: 必要最小限のスコープのみを要求する
- **トークンの安全な保管**: JWTトークンはクライアント側で安全に保管する
- **セッション有効期限**: 適切なセッション有効期限を設定する
- **リダイレクトURIの検証**: 認証後のリダイレクトURIを検証する
- **エラーハンドリング**: 認証エラーを適切に処理し、ユーザーにフィードバックを提供する

## CORS 対応ガイド

Cross-Origin Resource Sharing (CORS) は、異なるオリジン間でのリソース共有を制御するセキュリティ機構です。Next.js API Routes での CORS 対応方法を説明します。

### 1. CORS の基本設定

Next.js API Routes での基本的な CORS 設定:

```typescript
// pages/api/chat.ts
import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // CORS ヘッダーの設定
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*'); // 本番環境では特定のオリジンに制限すべき
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // OPTIONS リクエスト（プリフライトリクエスト）への対応
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // 実際の処理
  try {
    // APIロジック
    res.status(200).json({ message: 'Success' });
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
}
```

### 2. CORS ミドルウェアの作成

複数のAPIエンドポイントで再利用可能なCORSミドルウェア:

```typescript
// lib/cors.ts
import { NextApiRequest, NextApiResponse } from 'next';

type MiddlewareFunction = (
  req: NextApiRequest,
  res: NextApiResponse,
  next: () => void
) => void;

export const cors: MiddlewareFunction = (req, res, next) => {
  // 許可するオリジン（本番環境では特定のオリジンに制限すべき）
  const allowedOrigins = ['http://localhost:3000', 'https://あなたの本番ドメイン'];
  const origin = req.headers.origin;
  
  if (origin && allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  next();
};

// ミドルウェアを適用するヘルパー関数
export const withCors = (handler: any) => async (req: NextApiRequest, res: NextApiResponse) => {
  return new Promise((resolve, reject) => {
    cors(req, res, () => {
      return handler(req, res);
    });
  });
};
```

### 3. ミドルウェアの使用方法

```typescript
// pages/api/chat.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { withCors } from '../../lib/cors';

async function handler(req: NextApiRequest, res: NextApiResponse) {
  // APIロジック
  res.status(200).json({ message: 'Success' });
}

// CORSミドルウェアを適用
export default withCors(handler);
```

### 4. Next.js 13+ での CORS 設定 (App Router)

Next.js 13以降のApp Routerを使用している場合:

```typescript
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();
  
  // 許可するオリジン
  const allowedOrigins = ['http://localhost:3000', 'https://あなたの本番ドメイン'];
  const origin = request.headers.get('origin');
  
  if (origin && allowedOrigins.includes(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin);
  }
  
  response.headers.set('Access-Control-Allow-Credentials', 'true');
  response.headers.set('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  response.headers.set(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );
  
  return response;
}

export const config = {
  matcher: '/api/:path*',
};
```

### 5. CORS 実装のコツと注意点

- **オリジンの制限**: 本番環境では `Access-Control-Allow-Origin` を `*` ではなく、特定のオリジンに制限する
- **クレデンシャルの取り扱い**: `Access-Control-Allow-Credentials: true` を設定する場合、オリジンを `*` にはできない
- **プリフライトリクエスト**: OPTIONS リクエストを適切に処理する
- **キャッシュ制御**: `Access-Control-Max-Age` ヘッダーでプリフライトリクエストの結果をキャッシュできる
- **セキュリティ考慮事項**: CORS は同一オリジンポリシーの制限を緩和するため、必要最小限の設定にする
- **デバッグ**: CORS エラーは開発者ツールのコンソールで確認できる

## シークレット管理

このプロジェクトでは、API キーやモデルデータなどの機密情報を安全に管理するために、環境変数と GCP Secret Manager を併用しています。

### 1. 環境変数による管理

開発環境では `.env.local` ファイルを使用:

```
NEXT_PUBLIC_GEMINI_API_KEY=あなたのGemini APIキー
GOOGLE_CLIENT_ID=あなたのGoogleクライアントID
GOOGLE_CLIENT_SECRET=あなたのGoogleクライアントシークレット
NEXTAUTH_SECRET=ランダムな文字列
NEXTAUTH_URL=http://localhost:3000
```

### 2. GCP Secret Manager の設定

1. GCP コンソールで Secret Manager API を有効化
2. 新しいシークレットを作成:
   - `gemini-api-key`: Gemini API キー
   - `google-oauth-client-id`: Google OAuth クライアント ID
   - `google-oauth-client-secret`: Google OAuth クライアント シークレット
   - `nextauth-secret`: NextAuth.js 用のシークレット

### 3. Cloud Run でのシークレット参照

Cloud Run サービスにシークレットをマウントする設定:

```yaml
# cloudbuild.yaml
steps:
  # ...
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - 'gemini-flash-chat'
      - '--image=gcr.io/$PROJECT_ID/gemini-flash-chat'
      - '--platform=managed'
      - '--region=us-central1'
      - '--allow-unauthenticated'
      - '--set-secrets=GEMINI_API_KEY=gemini-api-key:latest,GOOGLE_CLIENT_ID=google-oauth-client-id:latest,GOOGLE_CLIENT_SECRET=google-oauth-client-secret:latest,NEXTAUTH_SECRET=nextauth-secret:latest'
      - '--set-env-vars=NEXTAUTH_URL=https://gemini-flash-chat-xxxxx-uc.a.run.app'
```

### 4. シークレット管理のベストプラクティス

- **最小権限の原則**: シークレットへのアクセス権限は必要最小限に制限する
- **環境分離**: 開発、テスト、本番環境でシークレットを分離する
- **ローテーション**: 定期的にシークレットをローテーションする
- **監査**: シークレットへのアクセスを監査する
- **暗号化**: 保存時と転送時の暗号化を確保する
- **バージョン管理**: シークレットのバージョン管理を行う

## デプロイ手順

このプロジェクトは Google Cloud Run にデプロイすることを想定しています。

### 1. 前提条件

- Google Cloud アカウント
- gcloud CLI のインストールと設定
- Docker のインストール

### 2. GCP プロジェクトの設定

```bash
# プロジェクトの作成（または既存のプロジェクトを使用）
gcloud projects create gemini-chat-project

# プロジェクトの選択
gcloud config set project gemini-chat-project

# 必要な API の有効化
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

### 3. シークレットの作成

```bash
# シークレットの作成
echo -n "あなたのGemini APIキー" | gcloud secrets create gemini-api-key --data-file=-
echo -n "あなたのGoogleクライアントID" | gcloud secrets create google-oauth-client-id --data-file=-
echo -n "あなたのGoogleクライアントシークレット" | gcloud secrets create google-oauth-client-secret --data-file=-
echo -n "ランダムな文字列" | gcloud secrets create nextauth-secret --data-file=-

# サービスアカウントにシークレットへのアクセス権を付与
gcloud secrets add-iam-policy-binding gemini-api-key \
  --member="serviceAccount:your-service-account@gemini-chat-project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
# 他のシークレットも同様に設定
```

### 4. ローカルでのビルドとテスト

```bash
# Dockerイメージのビルド
docker build -t gemini-flash-chat .

# ローカルでの実行
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_GEMINI_API_KEY=あなたのGemini APIキー \
  -e GOOGLE_CLIENT_ID=あなたのGoogleクライアントID \
  -e GOOGLE_CLIENT_SECRET=あなたのGoogleクライアントシークレット \
  -e NEXTAUTH_SECRET=ランダムな文字列 \
  -e NEXTAUTH_URL=http://localhost:3000 \
  gemini-flash-chat
```

### 5. Cloud Run へのデプロイ

```bash
# イメージのビルドとデプロイ
gcloud builds submit --tag gcr.io/gemini-chat-project/gemini-flash-chat

# Cloud Run サービスのデプロイ
gcloud run deploy gemini-flash-chat \
  --image gcr.io/gemini-chat-project/gemini-flash-chat \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-secrets=GEMINI_API_KEY=gemini-api-key:latest,GOOGLE_CLIENT_ID=google-oauth-client-id:latest,GOOGLE_CLIENT_SECRET=google-oauth-client-secret:latest,NEXTAUTH_SECRET=nextauth-secret:latest \
  --set-env-vars=NEXTAUTH_URL=https://gemini-flash-chat-xxxxx-uc.a.run.app
```

### 6. Cloud Build を使用した自動デプロイ

`cloudbuild.yaml` ファイルを使用して自動デプロイを設定:

```yaml
steps:
  # Dockerイメージのビルド
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/gemini-flash-chat', '.']
  
  # ビルドしたイメージをContainer Registryにプッシュ
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/gemini-flash-chat']
  
  # Cloud Runにデプロイ
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args:
      - 'run'
      - 'deploy'
      - 'gemini-flash-chat'
      - '--image=gcr.io/$PROJECT_ID/gemini-flash-chat'
      - '--platform=managed'
      - '--region=us-central1'
      - '--allow-unauthenticated'
      - '--set-secrets=GEMINI_API_KEY=gemini-api-key:latest,GOOGLE_CLIENT_ID=google-oauth-client-id:latest,GOOGLE_CLIENT_SECRET=google-oauth-client-secret:latest,NEXTAUTH_SECRET=nextauth-secret:latest'
      - '--set-env-vars=NEXTAUTH_URL=https://gemini-flash-chat-xxxxx-uc.a.run.app'

images:
  - 'gcr.io/$PROJECT_ID/gemini-flash-chat'
```

Cloud Build トリガーを設定して GitHub リポジトリと連携することで、コードの変更が自動的にデプロイされるようになります。

## トラブルシューティング

### 認証関連の問題

1. **リダイレクトURIエラー**:
   - Google Cloud Console で承認済みリダイレクト URI が正しく設定されているか確認
   - 本番環境の URL が正確に登録されているか確認

2. **セッションエラー**:
   - `NEXTAUTH_SECRET` が設定されているか確認
   - `NEXTAUTH_URL` が正しく設定されているか確認

3. **CORS エラー**:
   - API エンドポイントで CORS ヘッダーが正しく設定されているか確認
   - 許可されているオリジンが正しいか確認

### API 関連の問題

1. **Gemini API エラー**:
   - API キーが正しいか確認
   - API キーの権限が適切か確認
   - API の利用制限に達していないか確認

2. **レスポンスタイムアウト**:
   - Cloud Run のタイムアウト設定を確認
   - 長時間実行される処理を最適化

### デプロイ関連の問題

1. **ビルドエラー**:
   - Dockerfile の構文を確認
   - 依存関係が正しくインストールされているか確認

2. **環境変数の問題**:
   - シークレットが正しく設定されているか確認
   - 環境変数の名前が正しいか確認

3. **アクセス権限の問題**:
   - サービスアカウントに適切な権限が付与されているか確認
   - IAM ポリシーを確認

---

このプロジェクトについて質問や問題がある場合は、GitHub Issues で報告してください。
