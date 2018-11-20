let project = new Project('Shader');

project.addAssets('Assets/**');

project.addSources('Sources');

project.addShaders('Sources/Shaders/**');

resolve(project);
