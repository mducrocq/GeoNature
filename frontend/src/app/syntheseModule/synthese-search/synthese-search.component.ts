import { Component, OnInit, Output, EventEmitter, ViewChild } from '@angular/core';
import { FormBuilder } from '@angular/forms';
import { DataService } from '../services/data.service';
import { SyntheseFormService } from '../services/form.service';
import { NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { AppConfig } from '@geonature_config/app.config';
import { MapService } from '@geonature_common/map/map.service';
import {
  TreeComponent,
  TreeModel,
  TreeNode,
  TREE_ACTIONS,
  IActionMapping,
  ITreeOptions
} from 'angular-tree-component';
import { TaxonAdvancedModalComponent } from './taxon-advanced/taxon-advanced.component';
import { DataFormService } from '../../GN2CommonModule/form/data-form.service';

@Component({
  selector: 'pnx-synthese-search',
  templateUrl: 'synthese-search.component.html',
  styleUrls: ['synthese-search.component.scss'],
  providers: []
})
export class SyntheseSearchComponent implements OnInit {
  public AppConfig = AppConfig;

  public taxonApiEndPoint = `${AppConfig.API_ENDPOINT}/synthese/taxons_autocomplete`;
  @Output() searchClicked = new EventEmitter();
  constructor(
    private _fb: FormBuilder,
    public dataService: DataService,
    public formService: SyntheseFormService,
    public ngbModal: NgbModal,
    public mapService: MapService,
    private _dfs: DataFormService
  ) { }

  ngOnInit() { }

  onSubmitForm() {
    // mark as dirty to avoid set limit=100 when download
    this.formService.searchForm.markAsDirty();
    const updatedParams = this.formService.formatParams();
    this.searchClicked.emit(updatedParams);
  }

  refreshFilters() {
    this.formService.selectedtaxonFromComponent = [];
    this.formService.selectedCdRefFromTree = [];
    this.formService.searchForm.reset();
    // remove layers draw in the map
    console.log(this.mapService.releveFeatureGroup);
    this.mapService.removeAllLayers(this.mapService.map, this.mapService.releveFeatureGroup);
  }

  openModal(e, modalName) {
    const taxonModal = this.ngbModal.open(TaxonAdvancedModalComponent, {
      size: 'lg',
      backdrop: 'static',
      keyboard: false
    });
    // this.taxonModal.componentInstance.closeBtnName = 'close';
  }
}
