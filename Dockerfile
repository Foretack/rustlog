FROM node:18-alpine as frontend
WORKDIR /src/web
COPY web .
RUN yarn install --ignore-optional
RUN yarn build

FROM rust:1.70-bullseye AS chef
USER root
ENV CARGO_PROFILE_RELEASE_LTO=true
RUN cargo install cargo-chef
WORKDIR /app

FROM chef AS planner
COPY . . 
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
COPY --from=frontend /src/web web/
RUN cargo build --release

FROM debian:bullseye AS runtime
RUN useradd rustlog && mkdir /logs && chown rustlog: /logs
COPY --from=builder /app/target/release/rustlog /usr/local/bin/
USER rustlog
CMD ["/usr/local/bin/rustlog"]
