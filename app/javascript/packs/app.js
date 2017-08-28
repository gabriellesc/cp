/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import '../app-styles';

import React from 'react';
import ReactDOM from 'react-dom';

import { appState } from '../app/appState.js';
import { fetchAll } from '../app/fetch.js';

import { Navbar } from '../app/components/navbar.js';
import { ControlPanel } from '../app/components/controlPanel.js';

/*** Main app component ***/

class App extends React.Component {
    constructor(props) {
        super(props);

        // start fetching data
        fetchAll();
    }

    componentDidMount() {
        appState.subscribe(this.forceUpdate.bind(this, null));
    }

    render() {
        let role = this.props.appState.getCurrentUserRole();

        return (
            <div>
                <Navbar {...this.props} />

                {role == 'admin' && <ControlPanel {...this.props} />}
                {role == 'hris' && <ControlPanel {...this.props} />}
                {role == 'inst' && null}
                {role == 'student' && null}

                <div className="container-fluid" id="alert-container">
                    {this.props.appState
                        .getAlerts()
                        .map(alert =>
                            <div
                                key={'alert-' + alert.get('id')}
                                className="alert alert-danger"
                                onClick={() => this.props.appState.dismissAlert(alert.get('id'))}
                                onAnimationEnd={() =>
                                    this.props.appState.dismissAlert(alert.get('id'))}
                                dangerouslySetInnerHTML={{ __html: alert.get('text') }}
                            />
                        )}
                </div>
            </div>
        );
    }
}

document.addEventListener('DOMContentLoaded', () => {
    ReactDOM.render(<App appState={appState} />, document.getElementById('root'));
});
