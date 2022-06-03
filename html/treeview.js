Vue.component('tree-view', {
    name: "my-tree",
    props: ['treeData'],
    template: `
        <div class="tree">
            <ul>
            <li v-for="(node, index) in treeData" :key="index" class="part-list">
                <span class="part">{{index}}</span>
                <my-tree v-if="typeof node === 'object'" :tree-data="node"></my-tree>
                <input v-else type="text" v-bind:value="node">
            </li>
            </ul>
        </div>
    `
});