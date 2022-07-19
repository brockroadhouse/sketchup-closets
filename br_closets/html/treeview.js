Vue.component('tree-view', {
    name: "my-tree",
    props: [
        'treeData',
        'inputName',
        'handleChange',
        'parts'
    ],
    template: `
        <ul class="tree-list">
            <li v-for="(node, index) in treeData" :key="index" class="part-list">
                <label class="part inline field">
                    <span v-bind:class="typeof node === 'object' ? 'has-children' : ''">{{index}}</span>
                    <input type="checkbox" name="expand">

                    <my-tree v-if="typeof node === 'object'" :tree-data="node" 
                        :input-name="inputName+'.'+index" 
                        :handle-change="handleChange"
                        :parts="parts[index]"></my-tree>
                    <input v-else type="text" v-model="parts[index]" v-bind:name="inputName" @change="handleChange">
                </label>
            </li>
        </ul>
    `
});