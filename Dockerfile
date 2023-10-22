FROM ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnupg2 curl ca-certificates && \
    curl -fsSL https://packagecloud.io/jedrecord/repo1/gpgkey \
        | gpg --dearmor \
        > /etc/apt/trusted.gpg.d/jedrecord_repo1-archive-keyring.gpg && \
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/jedrecord_repo1-archive-keyring.gpg] https://packagecloud.io/jedrecord/repo1/any/ any main" \
        > /etc/apt/sources.list.d/jedrecord_repo1_any.list && \
    apt-get update && apt-get install -y sysinfo && \
    rm -rf /var/lib/apt/lists/*

