// (c) Cartesi and individual authors (see AUTHORS)
// SPDX-License-Identifier: Apache-2.0 (see LICENSE)

use tracing_subscriber::filter::{EnvFilter, LevelFilter};

// NOTE: doesn't support History upgradability.
// NOTE: doesn't support changing epoch_duration in the middle of things.
#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let filter = EnvFilter::builder()
        .with_default_directive(LevelFilter::INFO.into())
        .from_env_lossy();
    tracing_subscriber::fmt().with_env_filter(filter).init();

    let config = dispatcher::config::Config::initialize()?;
    dispatcher::run(config).await.map_err(|e| e.into())
}
