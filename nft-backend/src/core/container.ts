export interface AppContainer {
  initialized: boolean;

  database: boolean;
  blockchain: boolean;
  registry: boolean;
  socket: boolean;
}

export const container: AppContainer = {
  initialized: false,

  database: false,
  blockchain: false,
  registry: false,
  socket: false,
};