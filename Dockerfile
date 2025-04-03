# ビルドステージ
FROM node:18-alpine AS builder

WORKDIR /app

# 依存関係ファイルをコピー
COPY package.json package-lock.json ./

# 依存関係のインストール
RUN npm ci

# ソースコードをコピー
COPY . .

# アプリケーションのビルド
RUN npm run build

# 実行ステージ
FROM node:18-alpine AS runner

WORKDIR /app

# 環境変数の設定
ENV NODE_ENV=production

# 必要なファイルをビルドステージからコピー
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# アプリケーションの起動
CMD ["npm", "start"]
